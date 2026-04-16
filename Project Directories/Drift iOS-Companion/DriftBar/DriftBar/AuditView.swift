import SwiftUI
import AppKit

@MainActor
final class AuditStore: ObservableObject {
    static let shared = AuditStore()

    @Published var report: AuditEngine.Report?
    @Published var isScanning = false
    @Published var scanDirectory: URL?
    @Published var lastAutoScan: Date?

    private let engine = AuditEngine()

    func scan(at url: URL) {
        scanDirectory = url
        isScanning = true
        Task.detached { [engine] in
            let report = engine.scan(directory: url)
            await MainActor.run {
                self.report = report
                self.isScanning = false
                self.lastAutoScan = Date()
            }
        }
    }

    /// Called from DriftService on successful Xcode build.
    func autoScanIfConfigured(path: String) {
        guard !path.isEmpty else { return }
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else { return }
        scan(at: url)
    }
}

struct AuditView: View {
    @ObservedObject var store = AuditStore.shared
    @StateObject private var fixer = AuditFixer()
    @StateObject private var xsync = XcodeSync()
    @StateObject private var chat = ChatStore()
    @State private var missingCount: Int = 0
    @State private var needsThemeInit: Bool = false
    @State private var showChat: Bool = false
    @State private var selectedKind: Violation.Kind? = nil
    @State private var expandedFiles: Set<String> = []
    @State private var showFixConfirm = false
    @State private var fixerErrorMessage: String?

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                header
                Divider()
                if store.isScanning {
                    scanning
                } else if let report = store.report {
                    body(for: report)
                } else {
                    empty
                }
                if let stats = fixer.lastRunStats, !fixer.isRunning {
                    Divider()
                    resultBanner(stats)
                }
                if fixer.isRunning || !fixer.log.isEmpty {
                    Divider()
                    fixerPane
                }
            }
            .frame(minWidth: 560)
            if showChat {
                Divider()
                ChatPane(chat: chat, store: store, fixer: fixer)
                    .frame(width: 380)
                    .transition(.move(edge: .trailing))
            }
        }
        .frame(minWidth: 760, minHeight: 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: store.scanDirectory) { refreshMissingCount() }
        .onChange(of: store.report?.count) { refreshMissingCount() }
        .onAppear { refreshMissingCount() }
        .alert("Fix \(store.report?.count ?? 0) violations with Claude?",
               isPresented: $showFixConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Fix now") { startFix() }
        } message: {
            Text("Claude will edit files in-place. Files are tracked by git — review the diff after.")
        }
        .alert("Claude fixer error", isPresented: Binding(
            get: { fixerErrorMessage != nil },
            set: { if !$0 { fixerErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(fixerErrorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            headerTitle
            Spacer()
            headerBadges
            headerActions
        }
        .padding(.horizontal, Theme.Spacing.s5)
        .padding(.vertical, Theme.Spacing.s4)
    }

    @ViewBuilder private var headerTitle: some View {
        Image(systemName: "checkmark.seal")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Theme.Colors.accent)
        VStack(alignment: .leading, spacing: 2) {
            Text("Design audit").font(Theme.Typography.lg)
            if let dir = store.scanDirectory {
                Text(dir.lastPathComponent)
                    .font(Theme.Typography.sm)
                    .foregroundStyle(Theme.Colors.textDim)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    @ViewBuilder private var headerBadges: some View {
        if let r = store.report {
            HStack(spacing: Theme.Spacing.s2) {
                summaryBadge("\(r.scannedFiles) files", color: Theme.Colors.textDim)
                summaryBadge("\(r.count) issues", color: r.count == 0 ? Theme.Colors.pass : Theme.Colors.warn)
                summaryBadge(String(format: "%.2fs", r.elapsed), color: Theme.Colors.textDim)
            }
        }
    }

    @ViewBuilder private var headerActions: some View {
        if needsThemeInit {
            Button(action: initTheme) {
                Label("Initialize design system", systemImage: "paintpalette")
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.accent)
            .help("Drops drift.theme.json + Theme.swift so Claude has tokens to enforce")
        }
        if missingCount > 0, !xsync.isRunning {
            Button(action: runSync) {
                Label("Sync Xcode (\(missingCount))", systemImage: "square.and.arrow.down.on.square")
            }
            .buttonStyle(.bordered)
            .tint(Theme.Colors.warn)
            .help("Add files missing from the Xcode target")
        }
        if let r = store.report, r.count > 0 {
            Button(action: { showFixConfirm = true }) {
                Label("Fix with Claude", systemImage: "wand.and.stars")
            }
            .buttonStyle(.borderedProminent)
            .disabled(fixer.isRunning || store.isScanning)
            .help("Hand all \(r.count) violations to Claude Opus 4.6 — it will edit files in place to use Theme tokens, then DriftBar rescans and produces an HTML report")
        }
        Button(action: rescan) { Image(systemName: "arrow.clockwise") }
            .help("Rescan the project for design-system violations")
            .buttonStyle(.borderless)
            .disabled(store.isScanning || store.scanDirectory == nil)
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showChat.toggle() } }) {
            Image(systemName: showChat ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
        }
        .help(showChat ? "Hide the chat panel" : "Ask Drift about this audit — opens a chat panel")
        .buttonStyle(.borderless)
        .foregroundStyle(showChat ? Theme.Colors.accent : Theme.Colors.text)
    }

    private func body(for report: AuditEngine.Report) -> some View {
        HStack(spacing: 0) {
            kindSidebar(report)
                .frame(width: 220)
                .background(Theme.Colors.bgElevated)
            Divider()
            violationList(report)
        }
    }

    private func kindSidebar(_ report: AuditEngine.Report) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            kindRow(label: "All issues", count: report.count, kind: nil)
            Divider().padding(.vertical, Theme.Spacing.s2)
            ForEach(Violation.Kind.allKinds, id: \.self) { kind in
                let count = report.byKind[kind]?.count ?? 0
                if count > 0 {
                    kindRow(label: kind.label, count: count, kind: kind)
                }
            }
            Spacer()
            helpBlurb
        }
        .padding(Theme.Spacing.s3)
    }

    private func kindRow(label: String, count: Int, kind: Violation.Kind?) -> some View {
        let isSelected = selectedKind == kind
        return Button(action: { selectedKind = kind }) {
            HStack {
                Text(label).font(Theme.Typography.base)
                Spacer()
                Text("\(count)")
                    .font(Theme.Typography.sm.monospacedDigit())
                    .foregroundStyle(Theme.Colors.textDim)
            }
            .padding(.horizontal, Theme.Spacing.s3)
            .padding(.vertical, Theme.Spacing.s2)
            .background(isSelected ? Theme.Colors.bgRaised : .clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        }
        .buttonStyle(.plain)
    }

    private var helpBlurb: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
            Text("How to fix")
                .font(Theme.Typography.sm.bold())
                .foregroundStyle(Theme.Colors.textDim)
            Text("Replace flagged values with Theme.* tokens. Phase 3 will auto-fix via Claude.")
                .font(Theme.Typography.xs)
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .padding(Theme.Spacing.s3)
        .background(Theme.Colors.bgRaised)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }

    private func violationList(_ report: AuditEngine.Report) -> some View {
        let filtered = filteredViolations(report)
        let grouped = Dictionary(grouping: filtered, by: \.fileName).sorted { $0.key < $1.key }

        return ScrollView {
            if filtered.isEmpty {
                VStack(spacing: Theme.Spacing.s3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.Colors.pass)
                    Text("No violations")
                        .font(Theme.Typography.lg)
                    Text("This filter is clean.")
                        .font(Theme.Typography.sm)
                        .foregroundStyle(Theme.Colors.textDim)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.s8)
            } else {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.s2, pinnedViews: [.sectionHeaders]) {
                    ForEach(grouped, id: \.key) { file, items in
                        fileSection(file: file, items: items)
                    }
                }
                .padding(Theme.Spacing.s3)
            }
        }
    }

    private func fileSection(file: String, items: [Violation]) -> some View {
        let expanded = expandedFiles.contains(file) || expandedFiles.isEmpty
        return VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
            Button(action: { toggleFile(file) }) {
                HStack {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.Colors.textDim)
                        .frame(width: 12)
                    Text(file).font(Theme.Typography.base.bold())
                    Text("·").foregroundStyle(Theme.Colors.textDim)
                    Text("\(items.count)")
                        .font(Theme.Typography.sm.monospacedDigit())
                        .foregroundStyle(Theme.Colors.textDim)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: Theme.Spacing.s1) {
                    ForEach(items) { v in
                        violationRow(v)
                    }
                }
                .padding(.leading, Theme.Spacing.s4)
            }
        }
        .padding(.vertical, Theme.Spacing.s1)
    }

    private func violationRow(_ v: Violation) -> some View {
        Button(action: { reveal(v) }) {
            HStack(alignment: .top, spacing: Theme.Spacing.s3) {
                severityDot(v.severity)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Spacing.s2) {
                        Text(v.kind.label)
                            .font(Theme.Typography.base.bold())
                        Text("line \(v.line)")
                            .font(Theme.Typography.sm.monospacedDigit())
                            .foregroundStyle(Theme.Colors.textDim)
                    }
                    Text(v.snippet.trimmingCharacters(in: .whitespaces))
                        .font(Theme.Typography.mono)
                        .foregroundStyle(Theme.Colors.text)
                        .padding(.vertical, 2)
                        .padding(.horizontal, Theme.Spacing.s2)
                        .background(Theme.Colors.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                    Text("→ \(v.suggestion)")
                        .font(Theme.Typography.sm)
                        .foregroundStyle(Theme.Colors.textDim)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(Theme.Colors.textMuted)
            }
            .padding(Theme.Spacing.s3)
            .background(Theme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func severityDot(_ s: Violation.Severity) -> some View {
        Circle()
            .fill(color(for: s))
            .frame(width: 8, height: 8)
            .padding(.top, 6)
    }

    private func color(for s: Violation.Severity) -> Color {
        switch s {
        case .error: Theme.Colors.fail
        case .warn:  Theme.Colors.warn
        case .info:  Theme.Colors.accent
        }
    }

    private func summaryBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(Theme.Typography.sm.monospacedDigit())
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.s2)
            .padding(.vertical, 3)
            .background(Theme.Colors.bgElevated)
            .clipShape(Capsule())
    }

    private var scanning: some View {
        VStack(spacing: Theme.Spacing.s3) {
            ProgressView()
            Text("Scanning…")
                .font(Theme.Typography.sm)
                .foregroundStyle(Theme.Colors.textDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var empty: some View {
        VStack(spacing: Theme.Spacing.s4) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.textDim)
            Text("No project scanned yet")
                .font(Theme.Typography.lg)
            Button("Choose project folder…") { chooseAndScan() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func filteredViolations(_ r: AuditEngine.Report) -> [Violation] {
        guard let kind = selectedKind else { return r.violations }
        return r.violations.filter { $0.kind == kind }
    }

    private func toggleFile(_ file: String) {
        if expandedFiles.isEmpty { expandedFiles = Set(currentFileNames()) }
        if expandedFiles.contains(file) { expandedFiles.remove(file) }
        else { expandedFiles.insert(file) }
    }

    private func currentFileNames() -> [String] {
        guard let r = store.report else { return [] }
        return Array(Set(r.violations.map(\.fileName)))
    }

    private func rescan() {
        if let d = store.scanDirectory { store.scan(at: d) }
    }

    private func chooseAndScan() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose the project folder to audit"
        if panel.runModal() == .OK, let url = panel.url {
            store.scan(at: url)
        }
    }

    private func reveal(_ v: Violation) {
        let args = ["-g", "\(v.file.path):\(v.line)"]
        let task = Process()
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = ["--find", "xed"]
        let pipe = Pipe(); task.standardOutput = pipe
        try? task.run(); task.waitUntilExit()
        let xedPath = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "/usr/bin/xed"
        let open = Process()
        open.launchPath = xedPath
        open.arguments = args
        try? open.run()
    }
}

extension Violation.Kind {
    static var allKinds: [Violation.Kind] {
        [.hardcodedColor, .hexLiteral, .magicSpacing, .magicRadius, .rawFontSize, .magicOpacity]
    }
}

// MARK: - Fixer pane + actions

extension AuditView {
    fileprivate var fixerPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: fixer.isRunning ? "hourglass" : (fixer.lastExitCode == 0 ? "checkmark.circle.fill" : "text.bubble"))
                    .foregroundStyle(
                        fixer.isRunning ? Theme.Colors.warn :
                        (fixer.lastExitCode == 0 ? Theme.Colors.pass : Theme.Colors.accent)
                    )
                Text(fixer.isRunning ? "Claude is fixing violations…" : "Claude fix log")
                    .font(Theme.Typography.base.bold())
                Spacer()
                if !fixer.filesChanged.isEmpty {
                    Button("Reveal in Finder") { revealChangedInFinder() }
                        .buttonStyle(.borderless)
                }
                if fixer.isRunning {
                    Button("Cancel") { fixer.cancel() }
                        .buttonStyle(.borderless)
                } else if store.report != nil {
                    Button("Rescan") { rescan() }
                        .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, Theme.Spacing.s5)
            .padding(.vertical, Theme.Spacing.s3)
            .background(Theme.Colors.bgElevated)

            ScrollView {
                Text(fixer.log.isEmpty ? "(no output yet)" : fixer.log)
                    .font(Theme.Typography.mono)
                    .foregroundStyle(Theme.Colors.text)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.s4)
            }
            .frame(height: 180)
            .background(Theme.Colors.bg)
        }
    }

    fileprivate func startFix() {
        guard let report = store.report, let dir = store.scanDirectory else { return }
        Task {
            do {
                try await fixer.run(report: report, in: dir)
                // Auto-rescan so the user sees the drop in violation count.
                store.scan(at: dir)
            } catch {
                fixerErrorMessage = error.localizedDescription
            }
        }
    }

    fileprivate func resultBanner(_ stats: AuditFixer.RunStats) -> some View {
        HStack(spacing: Theme.Spacing.s4) {
            HStack(spacing: Theme.Spacing.s2) {
                Image(systemName: stats.fixed > 0 ? "sparkles" : "checkmark.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(stats.fixed > 0 ? Theme.Colors.accent : Theme.Colors.pass)
                VStack(alignment: .leading, spacing: 0) {
                    Text(stats.fixed > 0 ? "Fixed \(stats.fixed) violation\(stats.fixed == 1 ? "" : "s")" : "Already clean")
                        .font(Theme.Typography.lg)
                    Text("\(stats.before) → \(stats.after)  ·  \(stats.filesChanged) file\(stats.filesChanged == 1 ? "" : "s") changed  ·  \(String(format: "%.1fs", stats.elapsed))")
                        .font(Theme.Typography.sm)
                        .foregroundStyle(Theme.Colors.textDim)
                }
            }
            Spacer()
            if let url = fixer.lastReportURL {
                Button(action: { NSWorkspace.shared.open(url) }) {
                    HStack(spacing: Theme.Spacing.s1) {
                        Image(systemName: "doc.richtext")
                        Text("Open report")
                    }
                }
                .buttonStyle(.borderedProminent)
                .help("Open the HTML report in your browser — includes A/B screenshots (if configured), per-file diffs, and a violation-by-violation status list")
                Button(action: { NSWorkspace.shared.activateFileViewerSelecting([url]) }) {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Reveal the report folder in Finder")
            }
        }
        .padding(.horizontal, Theme.Spacing.s5)
        .padding(.vertical, Theme.Spacing.s3)
        .background(Theme.Colors.bgElevated)
    }

    fileprivate func runSync() {
        guard let dir = store.scanDirectory else { return }
        Task {
            do {
                try await xsync.sync(projectDir: dir)
                // Recompute missing after sync; rescan audit too since new files appeared.
                await MainActor.run {
                    missingCount = XcodeSync.missingFileCount(in: dir)
                }
                store.scan(at: dir)
            } catch {
                fixerErrorMessage = error.localizedDescription
            }
        }
    }

    fileprivate func refreshMissingCount() {
        if let dir = store.scanDirectory {
            missingCount = XcodeSync.missingFileCount(in: dir)
            needsThemeInit = !DesignSystemInitializer.isInitialized(in: dir)
        }
    }

    fileprivate func initTheme() {
        guard let dir = store.scanDirectory else { return }
        do {
            let r = try DesignSystemInitializer.initialize(in: dir)
            refreshMissingCount()
            // Rescan so the new Theme.swift shows up (and Xcode-sync count bumps).
            store.scan(at: dir)
            var msg = "Design system initialized."
            if r.jsonWasNew { msg += "\n+ drift.theme.json" }
            if r.swiftWasNew { msg += "\n+ Theme.swift at \(r.themeSwift.deletingLastPathComponent().lastPathComponent)/" }
            fixerErrorMessage = msg
        } catch {
            fixerErrorMessage = error.localizedDescription
        }
    }

    fileprivate func revealChangedInFinder() {
        guard let dir = store.scanDirectory else { return }
        NSWorkspace.shared.activateFileViewerSelecting(
            fixer.filesChanged.prefix(10).map { dir.appendingPathComponent($0) }
        )
    }
}
