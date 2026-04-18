import SwiftUI
import AppKit

/// Full-screen window for a live Claude Code session.
/// Modern SaaS-style dashboard: hero status card, three-metric row,
/// phase timeline, and a collapsible raw log for power users.
struct DriftSessionView: View {
    @ObservedObject var session: DriftSession
    @ObservedObject var recorder: SessionRecorder
    @ObservedObject var liveDiff: LiveGitWatcher
    @ObservedObject var explorer: AutoExplorer
    var projectDirectory: URL?

    @State private var tick = Date()
    @State private var showLog = true
    @State private var autoScroll = true
    @State private var pulse = false
    @State private var expandedDiffPath: String?
    @State private var expandedDiffText: String = ""
    @State private var deepCheck: Bool = false
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    init(session: DriftSession, projectDirectory: URL?) {
        self.session = session
        self.recorder = session.recorder
        self.liveDiff = session.liveDiff
        self.explorer = session.explorer
        self.projectDirectory = projectDirectory
    }

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Divider().opacity(0.4)

                ScrollView {
                    VStack(spacing: Theme.Spacing.s5) {
                        heroCard
                        if shouldShowMirror { simulatorMirrorCard }
                        if shouldShowExplorer { explorerCard }
                        metricsRow
                        phaseTimelineCard
                        if !liveDiff.changes.isEmpty {
                            liveDiffCard
                        } else if !session.filesChanged.isEmpty {
                            filesChangedCard
                        }
                        logCard
                    }
                    .padding(Theme.Spacing.s5)
                }
            }
        }
        .frame(minWidth: 760, minHeight: 520)
        .onReceive(timer) { tick = $0 }
        .onAppear { pulse = true }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Theme.Colors.bg,
                Theme.Colors.bgElevated.opacity(0.9),
                statusColor.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: Theme.Spacing.s3) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.accent)
            Text("Drift Session")
                .font(Theme.Typography.md)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.text)

            Text(session.command)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.Colors.textDim)
                .padding(.horizontal, Theme.Spacing.s2)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .fill(Theme.Colors.bgRaised)
                )

            if let name = projectDirectory?.lastPathComponent {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                    Text(name)
                        .font(Theme.Typography.sm)
                }
                .foregroundStyle(Theme.Colors.textDim)
            }

            Spacer()

            exploreToolbarButton

            if session.isRunning {
                Button(action: session.cancel) {
                    Label("Cancel", systemImage: "stop.fill")
                }
                .keyboardShortcut(".", modifiers: .command)
                .controlSize(.regular)
            } else if session.status != .idle {
                Button("Close") { closeWindow() }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.regular)
            }
        }
        .padding(.horizontal, Theme.Spacing.s5)
        .padding(.vertical, Theme.Spacing.s3)
        .background(.ultraThinMaterial)
    }

    // MARK: - Hero

    private var heroCard: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.s5) {
            // Left: status icon + pulse
            ZStack {
                if session.isRunning {
                    Circle()
                        .fill(statusColor.opacity(0.25))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulse ? 1.15 : 0.9)
                        .opacity(pulse ? 0.0 : 0.6)
                        .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)
                }
                Circle()
                    .fill(statusColor.opacity(0.18))
                    .frame(width: 72, height: 72)
                Image(systemName: statusIcon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: Theme.Spacing.s2) {
                    Text(statusTitle)
                        .font(Theme.Typography.xxl)
                        .foregroundStyle(Theme.Colors.text)
                    statusPill
                }
                Text(statusSubtitle)
                    .font(Theme.Typography.md)
                    .foregroundStyle(Theme.Colors.textDim)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            // Right: large elapsed timer
            VStack(alignment: .trailing, spacing: 2) {
                Text(elapsedString)
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Colors.text)
                    .monospacedDigit()
                Text("elapsed")
                    .font(Theme.Typography.xs)
                    .foregroundStyle(Theme.Colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(1.0)
            }
        }
        .padding(Theme.Spacing.s5)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    private var statusPill: some View {
        Text(statusLabel.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(statusColor)
            .padding(.horizontal, Theme.Spacing.s2)
            .padding(.vertical, 3)
            .background(Capsule().fill(statusColor.opacity(0.15)))
    }

    private var statusTitle: String {
        switch session.status {
        case .running:   return "Auditing…"
        case .succeeded: return "Audit complete"
        case .failed:    return "Audit failed"
        case .cancelled: return "Audit cancelled"
        case .idle:      return "Ready"
        }
    }

    private var statusSubtitle: String {
        if session.isRunning, let p = session.currentPhase { return p }
        if let err = session.lastError, session.status == .failed { return err }
        if session.status == .succeeded {
            let files = session.filesChanged.count
            if files > 0 {
                return "Drift made \(files) \(files == 1 ? "change" : "changes"). Review the log or the HTML report below."
            }
            return "Drift ran cleanly — no files modified. Open the HTML report for details."
        }
        if session.status == .cancelled { return "You stopped the session before it finished." }
        if projectDirectory != nil { return "Preparing Claude Code…" }
        return "Waiting for a project."
    }

    // MARK: - Auto-explorer (UI walker)

    private var shouldShowExplorer: Bool {
        switch explorer.state {
        case .idle: return false
        default: return true
        }
    }

    @ViewBuilder
    private var exploreToolbarButton: some View {
        switch explorer.state {
        case .exploring, .waitingForSimulator:
            Button(action: { explorer.stop() }) {
                Label("Stop walk", systemImage: "hand.raised.fill")
            }
            .controlSize(.regular)
        default:
            Button(action: startExplorer) {
                Label("Auto-walk UI", systemImage: "figure.walk.motion")
            }
            .controlSize(.regular)
            .help("Let Drift tap through every button in the running simulator")
        }
    }

    private func startExplorer() {
        guard let dir = projectDirectory else { return }
        explorer.start(projectDirectory: dir, maxSteps: 20, deepCheck: deepCheck)
    }

    private var explorerCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            HStack(spacing: Theme.Spacing.s2) {
                Label("Tester", systemImage: "figure.walk.motion")
                    .font(Theme.Typography.md)
                    .foregroundStyle(Theme.Colors.text)
                explorerStatePill
                Spacer()
                if explorer.state == .exploring {
                    Text("\(explorer.steps.count) / 20 steps")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.Colors.textDim)
                }
            }

            // Verdict summary is the headline answer: how many dead buttons
            // did we find, how many bugs? Show it as soon as there's a step,
            // so the user doesn't have to open the HTML report to see damage.
            if !explorer.steps.isEmpty {
                testerSummaryRow
            }

            switch explorer.state {
            case .unavailable(let reason):
                VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                    Text("`idb` not installed")
                        .font(Theme.Typography.sm)
                        .foregroundStyle(Theme.Colors.warn)
                    Text(reason)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textDim)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            case .failed(let msg):
                Text(msg)
                    .font(Theme.Typography.sm)
                    .foregroundStyle(Theme.Colors.fail)
            case .waitingForSimulator:
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Waiting for the simulator to boot before walking…")
                        .font(Theme.Typography.sm)
                        .foregroundStyle(Theme.Colors.textDim)
                }
            default:
                if explorer.steps.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                        Text("Drift will tap every reachable button and flag dead ones by comparing the screen before and after each tap.")
                            .font(Theme.Typography.sm)
                            .foregroundStyle(Theme.Colors.textDim)
                            .fixedSize(horizontal: false, vertical: true)
                        Toggle(isOn: $deepCheck) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Deep check (vision)")
                                    .font(Theme.Typography.sm)
                                    .foregroundStyle(Theme.Colors.text)
                                Text("Ask Claude to inspect each frame for layout bugs. ~3–5s per tap.")
                                    .font(Theme.Typography.xs)
                                    .foregroundStyle(Theme.Colors.textMuted)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                } else {
                    explorerStepsGrid
                }
            }

            if let url = explorer.reportURL,
               FileManager.default.fileExists(atPath: url.path) {
                HStack {
                    Spacer()
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Label("View report", systemImage: "doc.richtext")
                    }
                    .controlSize(.regular)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(Theme.Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    /// Counts per verdict — so the eyes land on "3 dead buttons" rather than
    /// scrolling 20 tiles to spot the red borders.
    private var testerSummaryRow: some View {
        let s = explorer.steps
        let responsive = s.filter { $0.verdict == .responsive }.count
        let dead = s.filter { $0.verdict == .unresponsive }.count
        let errors = s.filter { $0.verdict == .error }.count
        let bugs = s.reduce(0) { $0 + $1.bugs.count }
        return HStack(spacing: Theme.Spacing.s3) {
            testerStat(label: "Responsive", value: responsive, tint: Theme.Colors.pass)
            testerStat(label: "Dead buttons", value: dead, tint: Theme.Colors.fail)
            testerStat(label: "Errors", value: errors, tint: Theme.Colors.warn)
            testerStat(label: "Visual bugs", value: bugs, tint: Theme.Colors.warn)
        }
    }

    private func testerStat(label: String, value: Int, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(value > 0 ? tint : Theme.Colors.textMuted)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.Colors.textDim)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.horizontal, Theme.Spacing.s3)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(Theme.Colors.bg.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .strokeBorder(Theme.Colors.border.opacity(0.6), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var explorerStatePill: some View {
        let (label, color): (String, Color) = {
            switch explorer.state {
            case .idle:               return ("IDLE", Theme.Colors.textDim)
            case .unavailable:        return ("SETUP NEEDED", Theme.Colors.warn)
            case .waitingForSimulator:return ("WAITING", Theme.Colors.accent)
            case .exploring:          return ("WALKING", Theme.Colors.accent)
            case .finished:           return ("DONE", Theme.Colors.pass)
            case .failed:             return ("FAILED", Theme.Colors.fail)
            }
        }()
        Text(label)
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.s2)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.15)))
    }

    private var explorerStepsGrid: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: Theme.Spacing.s3) {
                ForEach(explorer.steps) { step in
                    ExplorerStepTile(step: step)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(height: 220)
    }

    // MARK: - Simulator mirror (live TV view)

    /// Only hide the mirror card once the session has fully idled with no
    /// recording ever started. During active runs or after a successful run
    /// (so users can open the MP4), keep it visible.
    private var shouldShowMirror: Bool {
        if session.isRunning { return true }
        if recorder.recordingURL != nil { return true }
        if recorder.currentFrame != nil { return true }
        return false
    }

    private var simulatorMirrorCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            HStack(spacing: Theme.Spacing.s2) {
                Label("Simulator", systemImage: "iphone.gen3")
                    .font(Theme.Typography.md)
                    .foregroundStyle(Theme.Colors.text)
                if let name = recorder.bootedDeviceName {
                    Text(name)
                        .font(Theme.Typography.sm)
                        .foregroundStyle(Theme.Colors.textDim)
                }
                Spacer()
                mirrorStatusBadge
            }

            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(Color.black.opacity(0.85))

                if let frame = recorder.currentFrame {
                    Image(nsImage: frame)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                        .overlay(alignment: .topLeading) { recordingBadge.padding(10) }
                        .overlay(alignment: .bottomTrailing) { frameCounterBadge.padding(10) }
                } else {
                    waitingForSimulatorOverlay
                }
            }
            .frame(minHeight: 360, maxHeight: 520)

            if let url = recorder.recordingURL, !session.isRunning,
               FileManager.default.fileExists(atPath: url.path) {
                HStack {
                    Spacer()
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Label("Play recording", systemImage: "play.rectangle.fill")
                    }
                    .controlSize(.small)
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    } label: {
                        Label("Reveal", systemImage: "folder")
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(Theme.Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    @ViewBuilder
    private var mirrorStatusBadge: some View {
        switch recorder.state {
        case .idle:
            EmptyView()
        case .waitingForSimulator:
            HStack(spacing: 5) {
                ProgressView().controlSize(.mini)
                Text("Waiting for simulator")
                    .font(Theme.Typography.xs)
                    .foregroundStyle(Theme.Colors.textDim)
            }
        case .recording:
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .opacity(pulse ? 1.0 : 0.35)
                Text("REC \(Self.formatDuration(recorder.recordingSeconds))")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.red)
            }
        case .stopped:
            Text("Recording saved")
                .font(Theme.Typography.xs)
                .foregroundStyle(Theme.Colors.pass)
        case .failed(let msg):
            Text(msg)
                .font(Theme.Typography.xs)
                .foregroundStyle(Theme.Colors.fail)
                .lineLimit(1)
        }
    }

    private var recordingBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            Text("REC")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.black.opacity(0.55)))
        .opacity(recorder.state == .idle || recorder.state == .waitingForSimulator ? 0 : 1)
    }

    private var frameCounterBadge: some View {
        Text("\(recorder.frameCount) frames")
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.75))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.black.opacity(0.55)))
    }

    private var waitingForSimulatorOverlay: some View {
        VStack(spacing: Theme.Spacing.s3) {
            Image(systemName: "iphone.gen3.slash")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white.opacity(0.4))
            Text(recorder.state == .waitingForSimulator
                 ? "Waiting for the simulator to boot…"
                 : "No simulator mirror yet")
                .font(Theme.Typography.sm)
                .foregroundStyle(.white.opacity(0.6))
            Text("Drift records automatically once the app launches.")
                .font(Theme.Typography.xs)
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.s5)
    }

    private static func formatDuration(_ s: TimeInterval) -> String {
        let secs = Int(s)
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }

    // MARK: - Metrics row

    private var metricsRow: some View {
        HStack(spacing: Theme.Spacing.s4) {
            MetricTile(
                icon: "waveform",
                tint: Theme.Colors.accent,
                value: "\(session.phases.count)",
                label: "Phases",
                footnote: phasesFootnote
            )
            MetricTile(
                icon: "wrench.and.screwdriver.fill",
                tint: Theme.Colors.accentSecondary,
                value: "\(session.toolCallCount)",
                label: "Tool calls",
                footnote: "Reads, edits, searches by Claude"
            )
            MetricTile(
                icon: "doc.badge.gearshape.fill",
                tint: session.filesChanged.isEmpty ? Theme.Colors.textMuted : Theme.Colors.pass,
                value: "\(session.filesChanged.count)",
                label: "Files changed",
                footnote: session.filesChanged.isEmpty ? "Nothing touched yet" : "New changes from this session"
            )
        }
    }

    private var phasesFootnote: String {
        if session.phases.isEmpty { return "Waiting for Claude's first update" }
        let active = session.phases.contains { $0.state == .active }
        if active { return "One phase in progress" }
        return "All phases resolved"
    }

    // MARK: - Phase timeline

    private var phaseTimelineCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            HStack {
                Label("Timeline", systemImage: "list.bullet.indent")
                    .font(Theme.Typography.md)
                    .foregroundStyle(Theme.Colors.text)
                Spacer()
                if session.isRunning {
                    HStack(spacing: 4) {
                        ProgressView().controlSize(.mini)
                        Text("live")
                            .font(Theme.Typography.xs)
                            .foregroundStyle(Theme.Colors.textDim)
                    }
                }
            }

            if session.phases.isEmpty {
                Text(session.isRunning ? "Claude is thinking…" : "No timeline captured.")
                    .font(Theme.Typography.sm)
                    .foregroundStyle(Theme.Colors.textDim)
                    .padding(.vertical, Theme.Spacing.s3)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(session.phases.enumerated()), id: \.element.id) { idx, phase in
                        PhaseRow(
                            phase: phase,
                            isLast: idx == session.phases.count - 1,
                            now: tick
                        )
                    }
                }
            }
        }
        .padding(Theme.Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    // MARK: - Files changed

    private var filesChangedCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            HStack {
                Label("Files changed", systemImage: "pencil.and.list.clipboard")
                    .font(Theme.Typography.md)
                    .foregroundStyle(Theme.Colors.text)
                Spacer()
                Text("\(session.filesChanged.count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Colors.pass)
                    .padding(.horizontal, Theme.Spacing.s2)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.Colors.pass.opacity(0.15)))
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(session.filesChanged.prefix(8), id: \.self) { file in
                    HStack(spacing: Theme.Spacing.s2) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.textDim)
                        Text(file)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Theme.Colors.text)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                if session.filesChanged.count > 8 {
                    Text("+ \(session.filesChanged.count - 8) more")
                        .font(Theme.Typography.sm)
                        .foregroundStyle(Theme.Colors.textMuted)
                        .padding(.top, 2)
                }
            }
        }
        .padding(Theme.Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    // MARK: - Live diff pane

    private var liveDiffCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            HStack {
                Label("Live changes", systemImage: "arrow.triangle.2.circlepath")
                    .font(Theme.Typography.md)
                    .foregroundStyle(Theme.Colors.text)
                if session.isRunning {
                    HStack(spacing: 4) {
                        ProgressView().controlSize(.mini)
                        Text("updating every 2s")
                            .font(Theme.Typography.xs)
                            .foregroundStyle(Theme.Colors.textDim)
                    }
                }
                Spacer()
                Text("\(liveDiff.changes.count) \(liveDiff.changes.count == 1 ? "file" : "files")")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Colors.accent)
                    .padding(.horizontal, Theme.Spacing.s2)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.Colors.accent.opacity(0.15)))
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(liveDiff.changes.prefix(12)) { change in
                    liveDiffRow(change)
                }
                if liveDiff.changes.count > 12 {
                    Text("+ \(liveDiff.changes.count - 12) more")
                        .font(Theme.Typography.sm)
                        .foregroundStyle(Theme.Colors.textMuted)
                        .padding(.top, 2)
                }
            }
        }
        .padding(Theme.Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    @ViewBuilder
    private func liveDiffRow(_ change: LiveGitWatcher.Change) -> some View {
        let isExpanded = expandedDiffPath == change.path
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { toggleExpanded(change) }) {
                HStack(spacing: Theme.Spacing.s2) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textDim)
                        .frame(width: 12)
                    Image(systemName: iconName(for: change.path))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.textDim)
                    Text(change.path)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.Colors.text)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    if change.additions > 0 {
                        Text("+\(change.additions)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.Colors.pass)
                    }
                    if change.deletions > 0 {
                        Text("-\(change.deletions)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.Colors.fail)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .fill(change.isNew ? Theme.Colors.accent.opacity(0.1) : Color.clear)
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView(.horizontal, showsIndicators: true) {
                    Text(expandedDiffText.isEmpty ? "Loading…" : expandedDiffText)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(Theme.Colors.text.opacity(0.85))
                        .textSelection(.enabled)
                        .padding(Theme.Spacing.s3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 280)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .fill(Theme.Colors.bg.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .strokeBorder(Theme.Colors.border, lineWidth: 1)
                )
                .padding(.leading, 24)
                .padding(.top, 4)
                .padding(.bottom, 6)
            }
        }
    }

    private func toggleExpanded(_ change: LiveGitWatcher.Change) {
        if expandedDiffPath == change.path {
            expandedDiffPath = nil
            expandedDiffText = ""
            return
        }
        expandedDiffPath = change.path
        expandedDiffText = ""
        liveDiff.diff(for: change.path) { text in
            // Drop stale completions if the user expanded a different row
            // before this one returned.
            if expandedDiffPath == change.path {
                expandedDiffText = text
            }
        }
        liveDiff.clearNewFlag(for: change.path)
    }

    private func iconName(for path: String) -> String {
        if path.hasSuffix(".swift") { return "swift" }
        if path.hasSuffix(".json") || path.hasSuffix(".plist") { return "curlybraces" }
        if path.hasSuffix(".md") { return "doc.text" }
        return "doc"
    }

    // MARK: - Raw log (collapsible)

    private var logCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showLog.toggle() } }) {
                HStack {
                    Label("Raw output", systemImage: "terminal")
                        .font(Theme.Typography.md)
                        .foregroundStyle(Theme.Colors.text)
                    Text("(from Claude Opus 4.7)")
                        .font(Theme.Typography.sm)
                        .foregroundStyle(Theme.Colors.textMuted)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textDim)
                        .rotationEffect(.degrees(showLog ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if showLog {
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(session.output.isEmpty ? "No output yet." : session.output)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .foregroundStyle(Theme.Colors.text.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Theme.Spacing.s3)
                            .id("output")
                    }
                    .frame(height: 320)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.md)
                            .fill(Theme.Colors.bg.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.md)
                            .strokeBorder(Theme.Colors.border, lineWidth: 1)
                    )
                    .onChange(of: session.output) { _, _ in
                        guard autoScroll else { return }
                        withAnimation(.easeOut(duration: 0.12)) {
                            proxy.scrollTo("output", anchor: .bottom)
                        }
                    }
                }

                HStack(spacing: Theme.Spacing.s2) {
                    Toggle("Auto-scroll", isOn: $autoScroll)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .font(Theme.Typography.sm)
                        .foregroundStyle(Theme.Colors.textDim)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(session.output, forType: .string)
                    } label: {
                        Label("Copy log", systemImage: "doc.on.clipboard")
                    }
                    .controlSize(.small)
                    .disabled(session.output.isEmpty)

                    if let url = latestReportURL() {
                        Button {
                            NSWorkspace.shared.open(url)
                        } label: {
                            Label("Open HTML report", systemImage: "doc.richtext")
                        }
                        .controlSize(.small)
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else if let url = latestReportURL() {
                HStack {
                    Spacer()
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Label("Open HTML report", systemImage: "doc.richtext")
                    }
                    .controlSize(.regular)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(Theme.Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    // MARK: - Shared styling

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.lg)
            .fill(Theme.Colors.bgElevated)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .strokeBorder(Theme.Colors.border.opacity(0.8), lineWidth: 1)
            )
            .themeShadow(Theme.ShadowStyle.sm)
    }

    private var statusColor: Color {
        switch session.status {
        case .running:   return Theme.Colors.accent
        case .succeeded: return Theme.Colors.pass
        case .failed:    return Theme.Colors.fail
        case .cancelled: return Theme.Colors.warn
        case .idle:      return Theme.Colors.textDim
        }
    }

    private var statusIcon: String {
        switch session.status {
        case .running:   return "waveform.badge.magnifyingglass"
        case .succeeded: return "checkmark.circle.fill"
        case .failed:    return "exclamationmark.triangle.fill"
        case .cancelled: return "stop.circle.fill"
        case .idle:      return "circle"
        }
    }

    private var statusLabel: String {
        switch session.status {
        case .running:   return "Running"
        case .succeeded: return "Done"
        case .failed:    return "Failed"
        case .cancelled: return "Cancelled"
        case .idle:      return "Idle"
        }
    }

    private var elapsedString: String {
        let _ = tick
        let seconds = Int(session.elapsed)
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Actions

    private func closeWindow() {
        DriftSessionWindowManager.shared.close()
    }

    private func latestReportURL() -> URL? {
        guard let dir = projectDirectory else { return nil }
        let reports = dir.appendingPathComponent("drift-reports", isDirectory: true)
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: reports,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }
        let runDirs = entries.filter {
            $0.hasDirectoryPath && $0.lastPathComponent.hasPrefix("run-")
        }
        let latest = runDirs.max(by: { a, b in
            let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return da < db
        })
        guard let runDir = latest else { return nil }
        let html = runDir.appendingPathComponent("report.html")
        return FileManager.default.fileExists(atPath: html.path) ? html : nil
    }
}

// MARK: - Metric tile

private struct MetricTile: View {
    let icon: String
    let tint: Color
    let value: String
    let label: String
    let footnote: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .fill(tint.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Spacer()
                Text(value)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Colors.text)
                    .monospacedDigit()
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.Colors.text)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(footnote)
                .font(Theme.Typography.xs)
                .foregroundStyle(Theme.Colors.textMuted)
                .lineLimit(1)
        }
        .padding(Theme.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Colors.bgElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colors.border.opacity(0.8), lineWidth: 1)
                )
        )
    }
}

// MARK: - Explorer step tile

private struct ExplorerStepTile: View {
    let step: AutoExplorer.Step

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            thumbnail
            HStack(spacing: 4) {
                Text("Step \(step.index + 1)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.Colors.text)
                Spacer()
                verdictPill
            }
            Text(step.targetLabel ?? step.action)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Theme.Colors.textDim)
                .lineLimit(2)
                .frame(maxWidth: 140, alignment: .leading)
            if !step.bugs.isEmpty {
                Text("\(step.bugs.count) bug\(step.bugs.count == 1 ? "" : "s")")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.Colors.warn)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Theme.Colors.warn.opacity(0.15))
                    )
            }
        }
        .frame(width: 140)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = step.screenshotPath,
           let img = NSImage(contentsOf: url) {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 140, height: 160)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .strokeBorder(verdictColor, lineWidth: 2)
                )
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(Color.black.opacity(0.2))
                .frame(width: 140, height: 160)
                .overlay(
                    Image(systemName: "xmark.octagon")
                        .foregroundStyle(Theme.Colors.textDim)
                )
        }
    }

    private var verdictColor: Color {
        switch step.verdict {
        case .responsive:   return Theme.Colors.pass
        case .unresponsive: return Theme.Colors.fail
        case .error:        return Theme.Colors.warn
        case .navigation:   return Theme.Colors.accent
        case .unknown:      return Theme.Colors.border
        }
    }

    private var verdictPill: some View {
        let (label, color): (String, Color) = {
            switch step.verdict {
            case .responsive:   return ("OK", Theme.Colors.pass)
            case .unresponsive: return ("DEAD", Theme.Colors.fail)
            case .error:        return ("ERR", Theme.Colors.warn)
            case .navigation:   return ("NAV", Theme.Colors.accent)
            case .unknown:      return ("?",   Theme.Colors.textDim)
            }
        }()
        return Text(label)
            .font(.system(size: 8, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.15)))
    }
}

// MARK: - Phase row

private struct PhaseRow: View {
    let phase: DriftSession.Phase
    let isLast: Bool
    let now: Date

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s3) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(dotColor.opacity(0.2))
                        .frame(width: 22, height: 22)
                    Image(systemName: dotIcon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(dotColor)
                }
                if !isLast {
                    Rectangle()
                        .fill(Theme.Colors.border)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(phase.text)
                    .font(Theme.Typography.base)
                    .foregroundStyle(Theme.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(durationLabel)
                    .font(Theme.Typography.xs)
                    .foregroundStyle(Theme.Colors.textMuted)
            }
            .padding(.bottom, isLast ? 0 : Theme.Spacing.s3)

            Spacer()
        }
    }

    private var dotColor: Color {
        switch phase.state {
        case .active:    return Theme.Colors.accent
        case .completed: return Theme.Colors.pass
        case .failed:    return Theme.Colors.fail
        }
    }

    private var dotIcon: String {
        switch phase.state {
        case .active:    return "circle.fill"
        case .completed: return "checkmark"
        case .failed:    return "xmark"
        }
    }

    private var durationLabel: String {
        let end = phase.endedAt ?? now
        let secs = max(0, Int(end.timeIntervalSince(phase.startedAt)))
        let suffix = phase.state == .active ? " (running)" : ""
        if secs < 60 { return "\(secs)s\(suffix)" }
        return "\(secs / 60)m \(secs % 60)s\(suffix)"
    }
}

// MARK: - Window manager

@MainActor
final class DriftSessionWindowManager: NSObject, NSWindowDelegate {
    static let shared = DriftSessionWindowManager()

    private var window: NSWindow?
    /// Package-internal so DriftService can observe status/phase and keep the
    /// menu bar header in sync without racing against this window's lifecycle.
    let session = DriftSession()

    /// Opens the session window and starts the given slash command.
    /// If a run is already in progress the existing window is brought forward.
    func start(slashCommand: String, projectDirectory: URL) {
        dismissMenuBarPopover()

        if window == nil {
            let view = DriftSessionView(session: session, projectDirectory: projectDirectory)
            let host = NSHostingView(rootView: view)
            let w = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1100, height: 780),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            w.title = "Drift Session — \(projectDirectory.lastPathComponent)"
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.contentView = host
            w.minSize = NSSize(width: 760, height: 520)
            w.center()
            w.isReleasedWhenClosed = false
            w.delegate = self
            w.backgroundColor = NSColor.windowBackgroundColor
            window = w
        } else {
            let view = DriftSessionView(session: session, projectDirectory: projectDirectory)
            window?.contentView = NSHostingView(rootView: view)
            window?.title = "Drift Session — \(projectDirectory.lastPathComponent)"
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if !session.isRunning {
            session.run(slashCommand: slashCommand, projectDirectory: projectDirectory)
        }
    }

    func close() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        if session.isRunning { session.cancel() }
        window = nil
    }

    private func dismissMenuBarPopover() {
        for win in NSApp.windows {
            let typeName = String(describing: type(of: win))
            if typeName.contains("StatusBar") || typeName.contains("MenuBarExtra") {
                win.close()
            }
        }
    }
}
