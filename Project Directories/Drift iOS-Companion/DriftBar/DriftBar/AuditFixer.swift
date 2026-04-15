import Foundation

/// Hands an audit report to Claude Code headless (`claude -p`) and applies fixes in-place.
/// The user sees streamed output and a final summary; files are edited on disk directly.
@MainActor
final class AuditFixer: ObservableObject {
    @Published var isRunning = false
    @Published var log: String = ""
    @Published var lastExitCode: Int32?
    @Published var filesChanged: [String] = []
    @Published var lastReportURL: URL?
    @Published var lastRunStats: RunStats?

    struct RunStats {
        let before: Int
        let after: Int
        let filesChanged: Int
        let elapsed: TimeInterval
        var fixed: Int { max(0, before - after) }
    }

    enum FixerError: Error, LocalizedError {
        case claudeNotFound
        case noViolations
        case themeMissing
        case dirtyGit(String)
        var errorDescription: String? {
            switch self {
            case .claudeNotFound:
                return "Claude CLI not found on PATH. Install from https://claude.com/code."
            case .noViolations:
                return "No violations to fix."
            case .themeMissing:
                return "Theme.swift not found in project. Click \"Initialize design system\" first — Claude can't reference tokens that don't exist."
            case .dirtyGit(let summary):
                return "Git working tree has uncommitted changes (\(summary)). Commit or stash first — the fixer writes over files and git is your undo."
            }
        }
    }

    /// Global flag so BuildWatcher can skip auto-audit while a fix is running
    /// (avoids after-capture rebuild re-firing the audit).
    @MainActor static var isActive: Bool = false

    private var process: Process?

    func cancel() {
        process?.terminate()
        process = nil
        isRunning = false
        append("\n⏹ cancelled by user")
    }

    func run(report: AuditEngine.Report, in projectDirectory: URL) async throws {
        guard !report.violations.isEmpty else { throw FixerError.noViolations }
        guard let claude = try? Self.findClaude() else { throw FixerError.claudeNotFound }
        guard DesignSystemInitializer.isInitialized(in: projectDirectory) else {
            throw FixerError.themeMissing
        }
        if let dirty = Self.gitDirtySummary(in: projectDirectory) {
            throw FixerError.dirtyGit(dirty)
        }

        Self.isActive = true
        defer { Self.isActive = false }

        let startedAt = Date()
        let beforeReport = report
        let prompt = Self.buildPrompt(report: report, projectDir: projectDirectory)

        // Optional: capture BEFORE screenshot if drift.capture.json is configured.
        let captureConfig = SimulatorCapture.loadConfig(in: projectDirectory)
        var beforeShot: URL?
        var afterShot: URL?
        if let cfg = captureConfig {
            append("📸 capturing BEFORE screenshot (\(cfg.deviceName))…\n")
            let shotsDir = projectDirectory
                .appendingPathComponent("drift-reports", isDirectory: true)
                .appendingPathComponent("_captures", isDirectory: true)
            let beforeURL = shotsDir.appendingPathComponent("before-\(UUID().uuidString.prefix(6)).png")
            do {
                let r = try await SimulatorCapture.captureScreenshot(
                    config: cfg,
                    projectDir: projectDirectory,
                    outputURL: beforeURL,
                    onLog: { [weak self] s in Task { @MainActor in self?.append(s) } }
                )
                beforeShot = r.imageURL
                append("  ✓ before.png (\(String(format: "%.1fs", r.elapsed)))\n")
            } catch {
                append("  ⚠️ before capture skipped: \(error.localizedDescription)\n")
            }
        }
        let promptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("drift-audit-\(UUID().uuidString.prefix(8)).md")
        try prompt.write(to: promptURL, atomically: true, encoding: .utf8)

        log = ""
        filesChanged = []
        lastExitCode = nil
        isRunning = true
        append("▶ running claude -p  (project: \(projectDirectory.lastPathComponent))\n")
        append("  prompt: \(promptURL.path)\n")
        append("  violations: \(report.count)\n\n")

        let task = Process()
        task.executableURL = URL(fileURLWithPath: claude)
        task.arguments = [
            "-p", prompt,
            "--dangerously-skip-permissions",
            "--output-format", "text"
        ]
        task.currentDirectoryURL = projectDirectory
        var env = ProcessInfo.processInfo.environment
        env["CLAUDE_CODE_ACTION"] = "drift-audit-fix"
        task.environment = env

        let stdout = Pipe(); let stderr = Pipe()
        task.standardOutput = stdout
        task.standardError  = stderr
        process = task

        stdout.fileHandleForReading.readabilityHandler = { [weak self] h in
            let data = h.availableData
            guard !data.isEmpty, let s = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in self?.append(s) }
        }
        stderr.fileHandleForReading.readabilityHandler = { [weak self] h in
            let data = h.availableData
            guard !data.isEmpty, let s = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in self?.append(s) }
        }

        do {
            try task.run()
        } catch {
            isRunning = false
            append("\n✘ failed to launch claude: \(error.localizedDescription)")
            throw error
        }

        await withCheckedContinuation { cont in
            task.terminationHandler = { p in
                DispatchQueue.main.async {
                    self.lastExitCode = p.terminationStatus
                    self.isRunning = false
                    self.process = nil
                    stdout.fileHandleForReading.readabilityHandler = nil
                    stderr.fileHandleForReading.readabilityHandler = nil
                    self.append("\n\(p.terminationStatus == 0 ? "✓" : "✘") exit \(p.terminationStatus)\n")
                    self.filesChanged = Self.gitChangedFiles(in: projectDirectory)
                    if !self.filesChanged.isEmpty {
                        self.append("changed: \(self.filesChanged.count) file(s)\n")
                        self.filesChanged.prefix(20).forEach { self.append("  • \($0)\n") }
                    }
                    cont.resume()
                }
            }
        }

        // Post-run: rescan + build HTML report comparing before/after.
        let afterReport = AuditEngine().scan(directory: projectDirectory)
        let gitDiff = Self.gitDiff(in: projectDirectory)

        // Optional: capture AFTER screenshot (rebuilds the app so the fixes are visible).
        if let cfg = captureConfig {
            append("📸 capturing AFTER screenshot (rebuilding)…\n")
            let shotsDir = projectDirectory
                .appendingPathComponent("drift-reports", isDirectory: true)
                .appendingPathComponent("_captures", isDirectory: true)
            let afterURL = shotsDir.appendingPathComponent("after-\(UUID().uuidString.prefix(6)).png")
            do {
                let r = try await SimulatorCapture.captureScreenshot(
                    config: cfg,
                    projectDir: projectDirectory,
                    outputURL: afterURL,
                    onLog: { [weak self] s in Task { @MainActor in self?.append(s) } }
                )
                afterShot = r.imageURL
                append("  ✓ after.png (\(String(format: "%.1fs", r.elapsed)))\n")
            } catch {
                append("  ⚠️ after capture skipped: \(error.localizedDescription)\n")
            }
        }

        let finishedAt = Date()
        do {
            let url = try AuditReportBuilder.build(AuditReportBuilder.Input(
                before: beforeReport,
                after: afterReport,
                changedFiles: self.filesChanged,
                gitDiff: gitDiff,
                projectDirectory: projectDirectory,
                fixerLog: self.log,
                startedAt: startedAt,
                finishedAt: finishedAt,
                beforeShot: beforeShot,
                afterShot: afterShot
            ))
            self.lastReportURL = url
            self.lastRunStats = RunStats(
                before: beforeReport.count,
                after: afterReport.count,
                filesChanged: self.filesChanged.count,
                elapsed: finishedAt.timeIntervalSince(startedAt)
            )
            self.append("📄 report: \(url.path)\n")
        } catch {
            self.append("⚠️ report build failed: \(error.localizedDescription)\n")
        }
    }

    private func append(_ s: String) { log += s }

    // MARK: - Prompt assembly

    private static func buildPrompt(report: AuditEngine.Report, projectDir: URL) -> String {
        var lines: [String] = []
        lines.append("# Drift design-audit fix request")
        lines.append("")
        lines.append("You are enforcing the project's design system. The canonical tokens live in `drift.theme.json` at the project root and are codified as Swift in `Theme.swift`. Every flagged location below must be replaced with the suggested Theme token (or equivalent) without changing visual intent.")
        lines.append("")
        lines.append("## Rules")
        lines.append("- Edit files in-place using the Edit tool. Do NOT ask for confirmation.")
        lines.append("- Do not touch Theme.swift itself.")
        lines.append("- Preserve existing indentation and surrounding code exactly.")
        lines.append("- If a suggestion is ambiguous (e.g., .opacity(0.37) has no clean tier), pick the nearest Theme token and add a one-line `// note:` only if behavior could shift.")
        lines.append("- After editing, do NOT run builds or tests — Drift will rescan automatically.")
        lines.append("- Skip any violation that would require restructuring (e.g., splitting an expression) — log it and move on.")
        lines.append("")
        lines.append("## Violations (\(report.count) total, across \(report.byFile.count) files)")
        lines.append("")
        for (file, items) in report.byFile.sorted(by: { $0.key < $1.key }) {
            lines.append("### \(file) — \(items.count)")
            lines.append("")
            for v in items {
                lines.append("- `\(v.file.path):\(v.line):\(v.column)` **\(v.kind.label)** — `\(v.snippet.trimmingCharacters(in: .whitespaces))` → \(v.suggestion)")
            }
            lines.append("")
        }
        lines.append("## When done")
        lines.append("Print a single summary line: `DRIFT_FIX_SUMMARY files=N edits=M skipped=K`")
        return lines.joined(separator: "\n")
    }

    // MARK: - Utilities

    private static func findClaude() throws -> String {
        // Try `which claude` first; fall back to common install paths.
        let which = Process()
        which.launchPath = "/bin/bash"
        which.arguments = ["-lc", "command -v claude || true"]
        let pipe = Pipe()
        which.standardOutput = pipe
        try which.run(); which.waitUntilExit()
        let found = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !found.isEmpty, FileManager.default.isExecutableFile(atPath: found) { return found }

        let candidates = [
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
            "\(NSHomeDirectory())/.claude/local/claude",
            "\(NSHomeDirectory())/.local/bin/claude"
        ]
        for c in candidates where FileManager.default.isExecutableFile(atPath: c) { return c }
        throw FixerError.claudeNotFound
    }

    /// Returns a short summary string if the working tree is dirty, else nil.
    /// Silently returns nil if the project isn't a git repo (can't enforce).
    private static func gitDirtySummary(in dir: URL) -> String? {
        let git = Process()
        git.launchPath = "/usr/bin/env"
        git.arguments = ["git", "-C", dir.path, "status", "--porcelain"]
        let outPipe = Pipe(); let errPipe = Pipe()
        git.standardOutput = outPipe
        git.standardError = errPipe
        do { try git.run(); git.waitUntilExit() } catch { return nil }
        guard git.terminationStatus == 0 else { return nil }   // not a git repo
        let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let lines = out.split(separator: "\n").filter { !$0.isEmpty }
        if lines.isEmpty { return nil }
        return "\(lines.count) modified file\(lines.count == 1 ? "" : "s")"
    }

    private static func gitDiff(in dir: URL) -> String {
        let git = Process()
        git.launchPath = "/usr/bin/env"
        git.arguments = ["git", "-C", dir.path, "diff", "HEAD", "--no-color", "--unified=3"]
        let pipe = Pipe()
        git.standardOutput = pipe
        git.standardError = Pipe()
        do { try git.run(); git.waitUntilExit() } catch { return "" }
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    private static func gitChangedFiles(in dir: URL) -> [String] {
        let git = Process()
        git.launchPath = "/usr/bin/env"
        git.arguments = ["git", "-C", dir.path, "status", "--porcelain"]
        let pipe = Pipe()
        git.standardOutput = pipe
        do { try git.run(); git.waitUntilExit() } catch { return [] }
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return out.split(separator: "\n").compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.count > 3 else { return nil }
            return String(trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces))
        }
    }
}
