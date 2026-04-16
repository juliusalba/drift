import SwiftUI

struct ChatPane: View {
    @ObservedObject var chat: ChatStore
    @ObservedObject var store: AuditStore
    @ObservedObject var fixer: AuditFixer
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messagesList
            Divider()
            inputBar
        }
        .background(Theme.Colors.bg)
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.s2) {
            Image(systemName: "bubble.left.and.bubble.right")
                .foregroundStyle(Theme.Colors.accent)
            Text("Ask Drift").font(Theme.Typography.lg)
            Spacer()
            if !chat.messages.isEmpty {
                Button(action: chat.clear) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Clear chat history")
            }
        }
        .padding(.horizontal, Theme.Spacing.s4)
        .padding(.vertical, Theme.Spacing.s3)
        .background(Theme.Colors.bgElevated)
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                    if chat.messages.isEmpty { emptyState }
                    ForEach(chat.messages) { msg in
                        bubble(for: msg).id(msg.id)
                    }
                    if chat.isAsking, let last = chat.messages.last, last.role == .assistant, last.body.isEmpty {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text("Thinking…").font(Theme.Typography.sm).foregroundStyle(Theme.Colors.textDim)
                        }
                        .padding(.horizontal, Theme.Spacing.s3)
                    }
                }
                .padding(Theme.Spacing.s3)
            }
            .onChange(of: chat.messages.last?.body) {
                if let id = chat.messages.last?.id {
                    withAnimation(.easeOut(duration: 0.15)) { proxy.scrollTo(id, anchor: .bottom) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
            Text("Ask about the current audit.")
                .font(Theme.Typography.md)
                .foregroundStyle(Theme.Colors.text)
            Text("Examples:")
                .font(Theme.Typography.sm)
                .foregroundStyle(Theme.Colors.textDim)
            ForEach(exampleQuestions, id: \.self) { q in
                Button(action: { chat.inputText = q; inputFocused = true }) {
                    HStack(spacing: Theme.Spacing.s1) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10))
                        Text(q)
                    }
                    .font(Theme.Typography.sm)
                    .foregroundStyle(Theme.Colors.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }

    private var exampleQuestions: [String] {
        [
            "Why doesn't the report have screenshots?",
            "What do hardcoded colors mean in my code?",
            "Which files have the most violations?",
            "How do I configure drift.capture.json?",
            "What's Theme.Spacing.s4?"
        ]
    }

    @ViewBuilder
    private func bubble(for msg: ChatStore.Message) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s2) {
            avatar(for: msg.role)
            VStack(alignment: .leading, spacing: 4) {
                Text(role(for: msg.role))
                    .font(Theme.Typography.xs.bold())
                    .foregroundStyle(Theme.Colors.textDim)
                Text(.init(msg.body.isEmpty ? "…" : msg.body))
                    .font(Theme.Typography.base)
                    .foregroundStyle(msg.role == .system ? Theme.Colors.warn : Theme.Colors.text)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.s3)
        .padding(.vertical, Theme.Spacing.s2)
        .background(msg.role == .user ? Theme.Colors.bgElevated : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }

    private func avatar(for role: ChatStore.Message.Role) -> some View {
        let (sym, color): (String, Color) = {
            switch role {
            case .user:      ("person.fill",        Theme.Colors.textDim)
            case .assistant: ("sparkles",           Theme.Colors.accent)
            case .system:    ("exclamationmark",    Theme.Colors.warn)
            }
        }()
        return Image(systemName: sym)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(color, in: Circle())
    }

    private func role(for role: ChatStore.Message.Role) -> String {
        switch role {
        case .user: "You"
        case .assistant: "Drift"
        case .system: "System"
        }
    }

    private var inputBar: some View {
        HStack(spacing: Theme.Spacing.s2) {
            TextField("Ask about this audit — what do I fix first?", text: $chat.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(Theme.Typography.md)
                .focused($inputFocused)
                .onSubmit(submit)
                .lineLimit(1...4)
                .padding(.horizontal, Theme.Spacing.s3)
                .padding(.vertical, Theme.Spacing.s2)
                .background(Theme.Colors.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            if chat.isAsking {
                Button(action: chat.cancel) {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.Colors.fail)
                .help("Cancel the in-flight question")
            } else {
                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                }
                .buttonStyle(.plain)
                .foregroundStyle(chat.inputText.isEmpty ? Theme.Colors.textMuted : Theme.Colors.accent)
                .disabled(chat.inputText.isEmpty)
                .keyboardShortcut(.return, modifiers: [])
                .help("Send (Return)")
            }
        }
        .padding(Theme.Spacing.s3)
    }

    private func submit() {
        chat.ask(
            question: chat.inputText,
            projectDir: store.scanDirectory,
            contextProvider: { buildContext() }
        )
    }

    private func buildContext() -> String {
        var lines: [String] = []
        if let dir = store.scanDirectory {
            lines.append("Project: \(dir.path)")
        }
        if let r = store.report {
            lines.append("Audit scanned \(r.scannedFiles) files, found \(r.count) violations (\(String(format: "%.2fs", r.elapsed))).")
            let byKind = r.byKind
            let parts = Violation.Kind.allKinds.compactMap { k -> String? in
                guard let n = byKind[k]?.count, n > 0 else { return nil }
                return "\(k.label)=\(n)"
            }
            if !parts.isEmpty { lines.append("By kind: \(parts.joined(separator: ", "))") }
            let topFiles = r.byFile.sorted { $0.value.count > $1.value.count }.prefix(5)
                .map { "\($0.key) (\($0.value.count))" }.joined(separator: ", ")
            if !topFiles.isEmpty { lines.append("Top files: \(topFiles)") }
        } else {
            lines.append("No audit has run yet. The Audit button opens the scanner.")
        }
        if let stats = fixer.lastRunStats {
            lines.append("Last fix run: \(stats.before) → \(stats.after) violations, \(stats.filesChanged) files changed in \(String(format: "%.1fs", stats.elapsed)).")
        } else {
            lines.append("No fix run has been performed yet.")
        }
        if let url = fixer.lastReportURL {
            lines.append("Latest HTML report: \(url.path)")
            let dir = url.deletingLastPathComponent()
            let hasBefore = FileManager.default.fileExists(atPath: dir.appendingPathComponent("before.png").path)
            let hasAfter  = FileManager.default.fileExists(atPath: dir.appendingPathComponent("after.png").path)
            lines.append("Screenshots: before=\(hasBefore), after=\(hasAfter). If both missing, drift.capture.json is not configured — the report will only have code diffs.")
        } else {
            lines.append("No HTML report yet. Report is produced after \"Fix with Claude\" runs.")
        }
        return lines.joined(separator: "\n")
    }
}
