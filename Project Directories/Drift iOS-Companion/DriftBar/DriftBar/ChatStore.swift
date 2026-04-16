import Foundation

/// Small conversational layer over `claude -p` so the user can ask questions
/// about the current audit state without leaving DriftBar.
@MainActor
final class ChatStore: ObservableObject {
    struct Message: Identifiable, Hashable {
        enum Role: String { case user, assistant, system }
        let id = UUID()
        let role: Role
        var body: String
        let at: Date
    }

    @Published var messages: [Message] = []
    @Published var isAsking = false
    @Published var inputText: String = ""
    @Published var lastError: String?

    private var currentTask: Task<Void, Never>?

    func ask(question rawQ: String, projectDir: URL?, contextProvider: () -> String) {
        let q = rawQ.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !isAsking else { return }

        messages.append(Message(role: .user, body: q, at: Date()))
        inputText = ""
        isAsking = true

        let context = contextProvider()
        let fullPrompt = """
        You are the Drift design-audit assistant. Answer the user's question using the audit state below.
        Keep answers short and concrete. If information is missing (no report, no screenshots, no fix run yet), say so explicitly and tell the user exactly which button to click in DriftBar to produce it.

        === AUDIT CONTEXT ===
        \(context)
        === END CONTEXT ===

        User question: \(q)
        """

        currentTask = Task { [weak self] in
            await self?.run(prompt: fullPrompt, projectDir: projectDir)
        }
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isAsking = false
    }

    func clear() {
        messages.removeAll()
        lastError = nil
    }

    private func run(prompt: String, projectDir: URL?) async {
        defer { Task { @MainActor in self.isAsking = false } }

        guard let claude = Self.findClaude() else {
            lastError = "claude CLI not on PATH"
            messages.append(Message(role: .system, body: "⚠️ claude CLI not found. Install from https://claude.com/code", at: Date()))
            return
        }

        // Pre-insert an empty assistant bubble so the UI can stream into it.
        let assistantID = Message(role: .assistant, body: "", at: Date())
        messages.append(assistantID)
        let idx = messages.count - 1

        let task = Process()
        task.executableURL = URL(fileURLWithPath: claude)
        task.arguments = [
            "-p", prompt,
            "--model", "opus",
            "--dangerously-skip-permissions",
            "--output-format", "text"
        ]
        if let projectDir { task.currentDirectoryURL = projectDir }

        let stdout = Pipe()
        let stderr = Pipe()
        task.standardOutput = stdout
        task.standardError  = stderr

        stdout.fileHandleForReading.readabilityHandler = { [weak self] h in
            let data = h.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in
                guard let self, idx < self.messages.count else { return }
                self.messages[idx].body += chunk
            }
        }
        stderr.fileHandleForReading.readabilityHandler = { _ in /* silent */ }

        do {
            try task.run()
        } catch {
            await MainActor.run {
                self.messages[idx].body = "⚠️ Couldn't launch claude: \(error.localizedDescription)"
            }
            return
        }

        await withCheckedContinuation { cont in
            task.terminationHandler = { _ in
                DispatchQueue.main.async {
                    stdout.fileHandleForReading.readabilityHandler = nil
                    stderr.fileHandleForReading.readabilityHandler = nil
                    cont.resume()
                }
            }
        }
    }

    // MARK: - Helpers

    private static func findClaude() -> String? {
        let which = Process()
        which.launchPath = "/bin/bash"
        which.arguments = ["-lc", "command -v claude || true"]
        let pipe = Pipe()
        which.standardOutput = pipe
        try? which.run(); which.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !out.isEmpty, FileManager.default.isExecutableFile(atPath: out) { return out }
        for p in ["/opt/homebrew/bin/claude", "/usr/local/bin/claude", NSHomeDirectory() + "/.claude/local/claude"] {
            if FileManager.default.isExecutableFile(atPath: p) { return p }
        }
        return nil
    }
}
