import Foundation

/// Polls `git diff --numstat` at a fixed interval while a session is running so
/// the UI can show files appearing/updating in real time — rather than waiting
/// for the run to finish. Paired with `DriftSession`: start when `run()` begins,
/// stop from `cancel()`/`finish()`.
///
/// Also exposes a per-file unified-diff fetcher so a click-to-expand UI doesn't
/// have to shell out on the main thread.
@MainActor
final class LiveGitWatcher: ObservableObject {

    struct Change: Identifiable, Equatable {
        let id: String        // path, used as stable identity
        var path: String
        var additions: Int
        var deletions: Int
        var firstSeen: Date
        var lastUpdated: Date
        var isNew: Bool       // true until the UI has had a chance to animate it in
    }

    @Published private(set) var changes: [Change] = []
    @Published private(set) var lastPollAt: Date?

    /// Baseline list of files already dirty before this session started — so we
    /// only surface changes the *session* produced, same pattern as DriftSession.
    private var baseline: Set<String> = []
    private var projectDirectory: URL?
    private var pollTimer: Timer?
    private var inFlight: Bool = false
    /// Cache of per-file full diff text; keyed by path. Reset each time the
    /// numstat for a file changes, so expanding shows fresh output.
    private var diffCache: [String: String] = [:]
    private var diffSignature: [String: String] = [:]  // path -> "+adds/-dels@lastUpdated"

    private let pollInterval: TimeInterval = 2.0

    // MARK: - Lifecycle

    func start(projectDirectory: URL, baselineFiles: [String]) {
        stop()
        self.projectDirectory = projectDirectory
        self.baseline = Set(baselineFiles)
        self.changes = []
        self.diffCache = [:]
        self.diffSignature = [:]
        self.lastPollAt = nil
        self.pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        // Fire once immediately so the UI doesn't sit empty for 2s.
        Task { @MainActor in self.poll() }
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Poll

    private func poll() {
        guard !inFlight, let dir = projectDirectory else { return }
        inFlight = true
        let base = baseline
        Task.detached { [weak self] in
            let rows = Self.gitNumstat(in: dir)
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.inFlight = false
                self.lastPollAt = Date()
                self.mergeRows(rows, baseline: base)
            }
        }
    }

    private func mergeRows(_ rows: [(path: String, additions: Int, deletions: Int)], baseline: Set<String>) {
        let now = Date()
        // Build a dict of newly-observed rows (filtering baseline).
        var seen: [String: (add: Int, del: Int)] = [:]
        for row in rows where !baseline.contains(row.path) {
            seen[row.path] = (row.additions, row.deletions)
        }

        var next: [Change] = []
        for existing in changes {
            if let observed = seen[existing.path] {
                var c = existing
                c.additions = observed.add
                c.deletions = observed.del
                c.lastUpdated = now
                c.isNew = false
                next.append(c)
                seen.removeValue(forKey: existing.path)
            } else {
                // File was reverted or is no longer part of the diff.
                // Keep it in the list but mark it visually by not updating
                // lastUpdated — the UI can fade it.
                next.append(existing)
            }
        }
        for (path, observed) in seen {
            next.append(Change(
                id: path,
                path: path,
                additions: observed.add,
                deletions: observed.del,
                firstSeen: now,
                lastUpdated: now,
                isNew: true
            ))
        }
        // Newest activity first.
        next.sort { $0.lastUpdated > $1.lastUpdated }
        self.changes = next
    }

    /// The UI should call this once it has animated in a new row so we don't
    /// mark it as "new" on every subsequent render. Idempotent.
    func clearNewFlag(for path: String) {
        guard let idx = changes.firstIndex(where: { $0.path == path }) else { return }
        if changes[idx].isNew {
            changes[idx].isNew = false
        }
    }

    // MARK: - Per-file diff

    /// Fetches the unified `git diff <path>` output. Caches so repeatedly
    /// expanding the same file during a quiet period doesn't shell out.
    func diff(for path: String, completion: @escaping (String) -> Void) {
        let sig = signature(for: path)
        if let cached = diffCache[path], diffSignature[path] == sig {
            completion(cached)
            return
        }
        guard let dir = projectDirectory else {
            completion("")
            return
        }
        Task.detached { [weak self] in
            let text = Self.gitUnifiedDiff(in: dir, path: path)
            await MainActor.run { [weak self] in
                self?.diffCache[path] = text
                self?.diffSignature[path] = sig
                completion(text)
            }
        }
    }

    private func signature(for path: String) -> String {
        guard let c = changes.first(where: { $0.path == path }) else { return "" }
        return "\(c.additions)/\(c.deletions)@\(Int(c.lastUpdated.timeIntervalSince1970))"
    }

    // MARK: - Shell helpers

    nonisolated private static func gitNumstat(in dir: URL) -> [(path: String, additions: Int, deletions: Int)] {
        // `git diff --numstat HEAD` also catches untracked-but-staged changes
        // via the working-tree-vs-HEAD comparison. Combined with `ls-files
        // --others --exclude-standard` we capture new files that Claude wrote.
        let diff = runGit(dir: dir, args: ["diff", "--numstat", "HEAD"])
        let untracked = runGit(dir: dir, args: ["ls-files", "--others", "--exclude-standard"])

        var results: [(String, Int, Int)] = []

        for line in diff.split(separator: "\n") {
            let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard parts.count >= 3 else { continue }
            let adds = Int(parts[0]) ?? 0
            let dels = Int(parts[1]) ?? 0
            let path = String(parts[2])
            results.append((path, adds, dels))
        }

        // Untracked files are "adds" with line count = file line count.
        for line in untracked.split(separator: "\n") {
            let path = String(line)
            guard !path.isEmpty else { continue }
            // Avoid double-counting: if already captured via diff, skip.
            if results.contains(where: { $0.0 == path }) { continue }
            let url = dir.appendingPathComponent(path)
            let lines = (try? String(contentsOf: url, encoding: .utf8))?
                .split(separator: "\n", omittingEmptySubsequences: false)
                .count ?? 0
            results.append((path, lines, 0))
        }

        return results
    }

    nonisolated private static func gitUnifiedDiff(in dir: URL, path: String) -> String {
        // Tracked: `git diff HEAD -- path`. Untracked (new file): diff against
        // /dev/null so we still show the file's contents as an addition.
        let tracked = runGit(dir: dir, args: ["diff", "HEAD", "--", path])
        if !tracked.isEmpty { return tracked }
        // Untracked — synthesize a diff-style dump.
        let url = dir.appendingPathComponent(path)
        guard let body = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        var out = "+++ \(path) (new file)\n"
        for line in body.split(separator: "\n", omittingEmptySubsequences: false) {
            out += "+\(line)\n"
        }
        return out
    }

    nonisolated private static func runGit(dir: URL, args: [String]) -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        proc.arguments = ["git", "-C", dir.path] + args
        let out = Pipe()
        proc.standardOutput = out
        proc.standardError = Pipe()
        do {
            try proc.run()
        } catch { return "" }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
