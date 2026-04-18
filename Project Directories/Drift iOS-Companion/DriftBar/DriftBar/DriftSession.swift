import Foundation

/// Runs a Claude Code slash command (e.g. `/drift-check`) headlessly via `claude -p`,
/// streams stdout/stderr into the UI, tracks duration/exit/files-changed, and mirrors
/// everything to `drift-reports/.driftbar-session.log` + `.driftbar-session.json` so
/// the result survives app restarts.
///
/// Unlike AuditFixer (which runs a fix prompt), this drives a supervisor command and
/// surfaces live status to a full-screen modal — the headless replacement for the
/// old "open Terminal" flow.
@MainActor
final class DriftSession: ObservableObject {

    enum Status: String, Codable {
        case idle
        case running
        case cancelled
        case succeeded
        case failed
    }

    @Published var status: Status = .idle
    @Published var output: String = ""
    @Published var command: String = ""
    @Published var startedAt: Date?
    @Published var endedAt: Date?
    @Published var exitCode: Int32?
    @Published var filesChanged: [String] = []
    @Published var lastError: String?

    /// Live simulator mirror + video recording. Starts as soon as `run()` fires
    /// and polls for a booted sim; begins recording the moment one shows up.
    let recorder = SessionRecorder()

    /// Live-updating list of files Claude has touched so far. Updates every
    /// ~2s during a session — complements the post-run `filesChanged` snapshot.
    let liveDiff = LiveGitWatcher()

    /// Opt-in: user kicks this off from the session window. Walks the booted
    /// simulator via `idb` taps to exercise every reachable screen/button.
    let explorer = AutoExplorer()

    /// Current one-line phase derived from the most recent meaningful output line.
    /// Surfaced in the modal header while running.
    @Published var currentPhase: String?

    /// Structured timeline of phases extracted from `⏺` markers in the stream.
    /// The last entry is the active phase (marked `.active`) until a newer one arrives
    /// or the session finishes.
    @Published var phases: [Phase] = []

    /// Count of tool invocations seen in the stream (file search, read, edit, bash).
    /// Surfaced as a metric card.
    @Published var toolCallCount: Int = 0

    struct Phase: Identifiable, Equatable {
        let id = UUID()
        var text: String
        var startedAt: Date
        var endedAt: Date?
        var state: State
        enum State { case active, completed, failed }
    }

    private var process: Process?
    private var stdoutHandler: FileHandle?
    private var stderrHandler: FileHandle?
    private var projectDirectory: URL?
    /// Snapshot of the git working tree *before* Claude starts, so we can diff
    /// against it on finish and show only the files this session touched.
    private var baselineDirtyFiles: Set<String> = []
    /// Monotonic run counter. Every `run()` bumps it and the termination handler
    /// captures it — if a stale subprocess terminates *after* a new run has started,
    /// its handler will see a mismatch and silently drop.
    private var runID: UInt64 = 0

    var elapsed: TimeInterval {
        guard let s = startedAt else { return 0 }
        return (endedAt ?? Date()).timeIntervalSince(s)
    }

    var isRunning: Bool { status == .running }

    // MARK: - Lifecycle

    /// Run a slash command against the given project. `slashCommand` should start with `/`.
    ///
    /// The UI state flip (`status = .running`, spinner, etc.) happens synchronously on
    /// the main actor so the session window paints immediately. Everything that shells
    /// out — `git status --porcelain`, `command -v claude` (which loads the user's full
    /// login shell), and `Process.run()` itself — is pushed onto a detached task so the
    /// menu bar popover stays interactive while Claude boots.
    func run(slashCommand: String, projectDirectory: URL) {
        guard !isRunning else { return }
        self.projectDirectory = projectDirectory
        self.command = slashCommand
        self.output = ""
        self.filesChanged = []
        self.exitCode = nil
        self.endedAt = nil
        self.lastError = nil
        self.currentPhase = "Starting…"
        self.phases = []
        self.toolCallCount = 0
        self.startedAt = Date()
        self.status = .running
        self.runID &+= 1
        self.baselineDirtyFiles = []
        let thisRun = self.runID

        writeStatusFile()

        // Kick off the simulator mirror / recorder in parallel. It waits for
        // a booted sim, so it's safe to start before Claude actually boots one.
        recorder.start(projectDirectory: projectDirectory)

        Task.detached { [weak self] in
            let baseline = Self.gitChangedFiles(in: projectDirectory)
            let claudePath = Self.findClaude()
            await MainActor.run { [weak self] in
                guard let self else { return }
                // Session got cancelled or a newer run replaced us while we were
                // shelling out — abandon quietly.
                guard self.runID == thisRun, self.status == .running else { return }
                self.baselineDirtyFiles = Set(baseline)
                self.liveDiff.start(projectDirectory: projectDirectory, baselineFiles: baseline)
                guard let claude = claudePath else {
                    self.append("\n⚠️ claude CLI not found on PATH. Install from https://claude.com/code\n")
                    self.finish(exit: 127, error: "claude CLI not found")
                    return
                }
                self.launchClaudeProcess(at: claude, slashCommand: slashCommand,
                                         projectDirectory: projectDirectory, thisRun: thisRun)
            }
        }
    }

    private func launchClaudeProcess(at claude: String,
                                     slashCommand: String,
                                     projectDirectory: URL,
                                     thisRun: UInt64) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: claude)
        task.arguments = [
            "-p", slashCommand,
            "--model", "claude-opus-4-7",
            "--dangerously-skip-permissions",
            "--output-format", "text"
        ]
        task.currentDirectoryURL = projectDirectory

        var env = ProcessInfo.processInfo.environment
        env["CLAUDE_CODE_ACTION"] = "drift-session"
        // Force Claude subscription (OAuth) — never API billing.
        for k in ["ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_BASE_URL",
                  "CLAUDE_CODE_USE_BEDROCK", "CLAUDE_CODE_USE_VERTEX"] {
            env.removeValue(forKey: k)
        }
        task.environment = env

        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardOutput = outPipe
        task.standardError = errPipe
        self.process = task
        self.stdoutHandler = outPipe.fileHandleForReading
        self.stderrHandler = errPipe.fileHandleForReading

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] h in
            let data = h.availableData
            guard !data.isEmpty else { return }
            let chunk = Self.decodeLossy(data)
            Task { @MainActor in self?.append(chunk) }
        }
        errPipe.fileHandleForReading.readabilityHandler = { [weak self] h in
            let data = h.availableData
            guard !data.isEmpty else { return }
            let chunk = Self.decodeLossy(data)
            Task { @MainActor in self?.append(chunk) }
        }

        task.terminationHandler = { [weak self] p in
            let code = p.terminationStatus
            Task { @MainActor in
                guard let self else { return }
                // Drop stale terminations: if the user cancelled and started a new
                // run before this subprocess actually exited, `thisRun` won't match
                // the current runID and we must not touch session state.
                guard self.runID == thisRun else { return }
                self.finish(exit: code, error: nil)
            }
        }

        do {
            try task.run()
        } catch {
            append("\n✘ failed to launch claude: \(error.localizedDescription)\n")
            finish(exit: -1, error: error.localizedDescription)
        }
    }

    func cancel() {
        guard isRunning else { return }
        append("\n⏹ cancelled by user\n")
        process?.terminate()
        status = .cancelled
        recorder.stop()
        liveDiff.stop()
        explorer.stop()
    }

    // MARK: - Output handling

    /// Cap the live `output` string at this many characters so SwiftUI's Text
    /// rendering stays snappy on long sessions. The full stream is still
    /// preserved on disk at `drift-reports/.driftbar-session.log`.
    private static let liveOutputCharCap = 200_000
    private static let liveOutputTrimTarget = 150_000

    private func append(_ chunk: String) {
        output += chunk
        if output.count > Self.liveOutputCharCap {
            let trimIdx = output.index(output.endIndex, offsetBy: -Self.liveOutputTrimTarget)
            output = "…(earlier output trimmed — full log on disk)\n" + output[trimIdx...]
        }
        ingestPhasesAndTools(from: chunk)
        appendToLogFile(chunk)
    }

    /// Parse a chunk for `⏺` status lines and tool-call markers, updating
    /// `phases`, `currentPhase`, and `toolCallCount` as we go.
    private func ingestPhasesAndTools(from chunk: String) {
        let lines = chunk.split(separator: "\n", omittingEmptySubsequences: true).map { String($0) }
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("⏺") {
                let body = line.dropFirst().trimmingCharacters(in: .whitespaces)
                guard !body.isEmpty else { continue }
                // Tool-call markers look like `ToolName(args)` — track them as a counter
                // rather than a timeline entry, so the phases list stays readable.
                if Self.looksLikeToolCall(body) {
                    toolCallCount += 1
                    continue
                }
                let text = String(body.prefix(140))
                // Close the previous active phase before pushing the new one.
                if let lastIdx = phases.indices.last, phases[lastIdx].state == .active {
                    phases[lastIdx].state = .completed
                    phases[lastIdx].endedAt = Date()
                }
                phases.append(Phase(text: text, startedAt: Date(), endedAt: nil, state: .active))
                currentPhase = text
            }
        }
    }

    /// Best-effort decode of a stdout chunk. If the bytes aren't clean UTF-8
    /// (happens occasionally when Claude emits a split multi-byte character
    /// across two reads), fall back to a lossy decode so we don't drop output.
    /// `nonisolated` because it's called from the Pipe readability handler
    /// (background queue), before we hop to the main actor.
    nonisolated private static func decodeLossy(_ data: Data) -> String {
        if let s = String(data: data, encoding: .utf8) { return s }
        return String(decoding: data, as: UTF8.self)
    }

    private static func looksLikeToolCall(_ body: String) -> Bool {
        // Claude Code prints tool calls as `Search(pattern: ...)`, `Read(file: ...)`,
        // `Bash(...)`, etc. — a capital-letter identifier immediately followed by `(`.
        guard let paren = body.firstIndex(of: "(") else { return false }
        let head = body[..<paren]
        guard let first = head.first, first.isUppercase else { return false }
        return head.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    // MARK: - Finish

    private func finish(exit code: Int32, error: String?) {
        exitCode = code
        endedAt = Date()
        if let error { lastError = error }

        // Release the process + pipe references now that the subprocess has
        // exited. Leaving them around holds file descriptors open inside the
        // singleton for no benefit.
        stdoutHandler?.readabilityHandler = nil
        stderrHandler?.readabilityHandler = nil
        stdoutHandler = nil
        stderrHandler = nil
        process = nil

        // Only downgrade to success/failure if we weren't explicitly cancelled.
        if status != .cancelled {
            status = (code == 0) ? .succeeded : .failed
        }

        // Close out any still-active phase so the timeline resolves cleanly.
        if let lastIdx = phases.indices.last, phases[lastIdx].state == .active {
            phases[lastIdx].endedAt = Date()
            phases[lastIdx].state = (status == .succeeded) ? .completed : .failed
        }

        let verdict: String
        switch status {
        case .succeeded: verdict = "✓ finished"
        case .cancelled: verdict = "⏹ cancelled"
        case .failed:    verdict = "✘ failed"
        default:         verdict = "— idle"
        }
        append("\n\(verdict) (exit \(code), \(String(format: "%.1fs", elapsed)))\n")
        currentPhase = nil
        writeStatusFile()

        // Finalize the MP4 alongside the log so users end up with a matched
        // pair at drift-reports/sessions/{stamp}/{recording.mp4, session.log}.
        recorder.stop()
        liveDiff.stop()
        if let sessionDir = recorder.sessionDir {
            copyLogToSession(dir: sessionDir)
        }

        // Post-run `git status` is shelled out, so push it off the main actor.
        // The summary line(s) appear in the log once the diff resolves — the
        // terminal verdict above is what the user sees instantly.
        if let dir = projectDirectory {
            let baseline = baselineDirtyFiles
            let sessionRunID = self.runID
            Task.detached { [weak self] in
                let current = Self.gitChangedFiles(in: dir)
                let changed = current.filter { !baseline.contains($0) }
                await MainActor.run { [weak self] in
                    guard let self, self.runID == sessionRunID else { return }
                    self.filesChanged = changed
                    if !changed.isEmpty {
                        self.append("changed: \(changed.count) file(s)\n")
                        changed.prefix(20).forEach { self.append("  • \($0)\n") }
                    }
                    self.writeStatusFile()
                }
            }
        }
    }

    // MARK: - Durable logs

    private func logURL() -> URL? {
        guard let dir = projectDirectory else { return nil }
        let reports = dir.appendingPathComponent("drift-reports", isDirectory: true)
        try? FileManager.default.createDirectory(at: reports, withIntermediateDirectories: true)
        return reports.appendingPathComponent(".driftbar-session.log")
    }

    private func statusURL() -> URL? {
        guard let dir = projectDirectory else { return nil }
        let reports = dir.appendingPathComponent("drift-reports", isDirectory: true)
        try? FileManager.default.createDirectory(at: reports, withIntermediateDirectories: true)
        return reports.appendingPathComponent(".driftbar-session.json")
    }

    /// Copy the running session log into the recorder's session directory so
    /// the MP4 and log live side-by-side. Best-effort — runs off the main
    /// actor so a slow disk doesn't stall the finish.
    private func copyLogToSession(dir: URL) {
        guard let src = logURL() else { return }
        let dest = dir.appendingPathComponent("session.log")
        Task.detached {
            try? FileManager.default.copyItem(at: src, to: dest)
        }
    }

    private func appendToLogFile(_ chunk: String) {
        guard let url = logURL(), let data = chunk.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: url) {
            do {
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.close()
            } catch {
                // Log write is best-effort — swallow and move on.
            }
        } else {
            try? data.write(to: url)
        }
    }

    private func writeStatusFile() {
        guard let url = statusURL() else { return }
        struct Snapshot: Encodable {
            let status: String
            let command: String
            let startedAt: Date?
            let endedAt: Date?
            let exitCode: Int32?
            let filesChanged: [String]
            let currentPhase: String?
        }
        let snap = Snapshot(
            status: status.rawValue,
            command: command,
            startedAt: startedAt,
            endedAt: endedAt,
            exitCode: exitCode,
            filesChanged: filesChanged,
            currentPhase: currentPhase
        )
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(snap) {
            try? data.write(to: url)
        }
    }

    // MARK: - Helpers

    /// Cached result of the `claude` CLI lookup. The `bash -lc` probe is expensive
    /// (loads the user's full login shell) and the location doesn't move between
    /// Runs, so memoize it for the app's lifetime. Thread-safe via lock because the
    /// lookup runs on a detached task.
    nonisolated(unsafe) private static var _cachedClaudePath: String?
    nonisolated private static let _claudeLock = NSLock()

    nonisolated private static func findClaude() -> String? {
        _claudeLock.lock()
        if let cached = _cachedClaudePath {
            _claudeLock.unlock()
            return cached
        }
        _claudeLock.unlock()

        let which = Process()
        which.launchPath = "/bin/bash"
        which.arguments = ["-lc", "command -v claude || true"]
        let pipe = Pipe()
        which.standardOutput = pipe
        which.standardError = Pipe()
        try? which.run()
        // Read BEFORE waitUntilExit so the subprocess can't deadlock writing
        // into a full pipe buffer (bash -lc can be chatty if .zshrc prints).
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        which.waitUntilExit()
        let found = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var resolved: String?
        if !found.isEmpty, FileManager.default.isExecutableFile(atPath: found) {
            resolved = found
        } else {
            let candidates = [
                "/opt/homebrew/bin/claude",
                "/usr/local/bin/claude",
                "\(NSHomeDirectory())/.claude/local/claude",
                "\(NSHomeDirectory())/.local/bin/claude"
            ]
            resolved = candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
        }
        if let resolved {
            _claudeLock.lock()
            _cachedClaudePath = resolved
            _claudeLock.unlock()
        }
        return resolved
    }

    nonisolated private static func gitChangedFiles(in dir: URL) -> [String] {
        let git = Process()
        git.launchPath = "/usr/bin/env"
        git.arguments = ["git", "-C", dir.path, "status", "--porcelain"]
        let pipe = Pipe()
        git.standardOutput = pipe
        git.standardError = Pipe()
        do { try git.run() } catch { return [] }
        // Read BEFORE waitUntilExit. On a project with hundreds of dirty
        // files, `git status --porcelain` can push past the 64KB pipe buffer;
        // the original ordering would then have the subprocess block on write
        // while we block on exit — classic deadlock.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        git.waitUntilExit()
        guard git.terminationStatus == 0 else { return [] }
        let out = String(data: data, encoding: .utf8) ?? ""
        return out.split(separator: "\n").compactMap { line -> String? in
            let s = line.trimmingCharacters(in: .whitespaces)
            guard s.count > 3 else { return nil }
            return String(s.dropFirst(3))
        }
    }
}
