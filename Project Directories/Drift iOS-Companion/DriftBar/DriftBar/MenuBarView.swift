import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var service: DriftService
    @State private var selectedScreen: DriftScreen?
    @State private var hoveredScreen: String?
    @State private var screenFilter: ScreenFilter = .all
    @State private var showQuitConfirm = false

    enum ScreenFilter: String, CaseIterable {
        case all = "All"
        case failing = "Failing"
        case issues = "Has Issues"
        case passing = "Passing"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider().opacity(0.5)

            ScrollView {
                VStack(spacing: 0) {
                    if let run = service.latestRun {
                        scoreHero(run: run)
                            .padding(.horizontal, 14)
                            .padding(.top, 12)
                            .padding(.bottom, 6)
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))

                        screenGrid(run: run)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 8)

                        if let screen = selectedScreen {
                            screenDetail(screen: screen)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 8)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    } else if !service.settings.watchedProjectPath.isEmpty {
                        waitingState
                            .padding(.vertical, 24)
                            .transition(.opacity)
                    } else {
                        onboardingState
                            .padding(.vertical, 16)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: service.latestRun != nil)
            }

            Divider().opacity(0.5)
            actionsBar
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .frame(width: 420, height: 560)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.blue.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image("MenuBarIcon")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .opacity(0.9)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Drift")
                    .font(.system(size: 14, weight: .bold))
                if !service.settings.watchedProjectPath.isEmpty {
                    Text(projectName)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if service.isRunning {
                HStack(spacing: 5) {
                    ProgressView()
                        .controlSize(.small)
                    Text(service.currentPhase ?? "Analyzing...")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            } else if let error = service.lastError {
                Button {
                    service.lastError = nil
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                        Text("Error")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help(friendlyError(error))
            } else if let run = service.latestRun {
                HStack(spacing: 4) {
                    Image(systemName: statusSymbol(run.summary.overallScore))
                        .font(.system(size: 9))
                    Text(run.summary.overallScore.scoreFormatted)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(scoreColor(run.summary.overallScore))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(scoreColor(run.summary.overallScore).opacity(0.08))
                .clipShape(Capsule())
                .accessibilityLabel("Score: \(run.summary.overallScore.scoreFormatted), \(statusLabel(run.summary.overallScore))")
            }
        }
    }

    private var projectName: String {
        URL(fileURLWithPath: service.settings.watchedProjectPath).lastPathComponent
    }

    // MARK: - Score Hero

    private func scoreHero(run: DriftRun) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.05), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: run.summary.overallScore)
                    .stroke(
                        scoreColor(run.summary.overallScore),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: run.summary.overallScore)

                VStack(spacing: 0) {
                    Text(run.summary.overallScore.scoreFormatted)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(scoreColor(run.summary.overallScore))
                    Text("score")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.quaternary)
                        .textCase(.uppercase)
                }
            }
            .frame(width: 68, height: 68)
            .accessibilityLabel("Overall score: \(run.summary.overallScore.scoreFormatted)")

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 0) {
                    miniStat("\(run.summary.passingScreens)/\(run.summary.totalScreens)", label: "screens", color: .green)
                    Spacer()
                    miniStat("\(run.summary.autoFixed)", label: "fixed", color: .blue)
                    Spacer()
                    miniStat("\(run.summary.totalIterations)", label: "iters", color: .primary)
                }

                HStack(spacing: 4) {
                    let issues = run.summary.criticalIssues + run.summary.majorIssues
                    if issues > 0 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                        Text("\(issues) issue\(issues == 1 ? "" : "s") remaining")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.green)
                        Text("All checks passed")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(status: run.summary.status)
                }
            }
        }
    }

    private func miniStat(_ value: String, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color == .primary ? nil : color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.quaternary)
        }
    }

    // MARK: - Screen Grid

    private func screenGrid(run: DriftRun) -> some View {
        let filteredScreens = run.screens.filter { screen in
            switch screenFilter {
            case .all: return true
            case .failing: return screen.score < 0.7
            case .issues: return !screen.discrepancies.filter({ $0.status == .open }).isEmpty
            case .passing: return screen.score >= 0.9
            }
        }

        return VStack(alignment: .leading, spacing: 6) {
            // Filter bar
            HStack(spacing: 0) {
                ForEach(ScreenFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            screenFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 10, weight: screenFilter == filter ? .semibold : .regular))
                            .foregroundStyle(screenFilter == filter ? .primary : .tertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(screenFilter == filter ? Color.primary.opacity(0.06) : Color.clear)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Text("\(filteredScreens.count)/\(run.screens.count)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 6)

            if filteredScreens.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(.tertiary)
                        Text("No screens match this filter")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6),
                ], spacing: 6) {
                    ForEach(filteredScreens) { screen in
                        screenCard(screen: screen)
                    }
                }
            }
        }
    }

    private func screenCard(screen: DriftScreen) -> some View {
        let isSelected = selectedScreen?.name == screen.name
        let isHovered = hoveredScreen == screen.name
        let openIssues = screen.discrepancies.filter { $0.status == .open }.count
        let hasScreenshot = service.findScreenshot(for: screen.name) != nil

        return VStack(alignment: .leading, spacing: 0) {
            // Preview
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(isHovered ? 0.05 : 0.025))

                if let nsImage = service.findScreenshot(for: screen.name) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 80)
                        .clipped()
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "camera.slash")
                            .font(.system(size: 14))
                            .foregroundStyle(.quaternary)
                        Text("No screenshot")
                            .font(.system(size: 8))
                            .foregroundStyle(.quaternary)
                    }
                }

                // Overlay
                VStack {
                    HStack {
                        if isHovered && hasScreenshot {
                            Button {
                                if let img = service.findScreenshot(for: screen.name) {
                                    ScreenPreviewWindowManager.shared.open(
                                        screenName: screen.name,
                                        score: screen.score,
                                        image: img
                                    )
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "eye.fill")
                                        .font(.system(size: 8))
                                    Text("View")
                                        .font(.system(size: 9, weight: .medium))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        HStack(spacing: 3) {
                            Image(systemName: statusSymbol(screen.score))
                                .font(.system(size: 7))
                            Text(screen.score.scoreFormatted)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(scoreColor(screen.score))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .padding(5)
                    Spacer()
                }
            }
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(screen.name)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: statusSymbol(screen.score))
                        .font(.system(size: 7))
                        .foregroundStyle(scoreColor(screen.score))
                    if openIssues > 0 {
                        Text("\(openIssues) issue\(openIssues == 1 ? "" : "s")")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                    } else {
                        Text("Passing")
                            .font(.system(size: 9))
                            .foregroundStyle(.green.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 5)
            .padding(.bottom, 2)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.primary.opacity(0.06) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isSelected ? scoreColor(screen.score).opacity(0.3) : Color.primary.opacity(0.04),
                    lineWidth: isSelected ? 1.5 : 0.5
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedScreen = isSelected ? nil : screen
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                hoveredScreen = hovering ? screen.name : nil
            }
        }
        .contextMenu {
            Button("Copy Score") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(screen.score.scoreFormatted, forType: .string)
            }
            if hasScreenshot {
                Button("Preview Screenshot") {
                    if let img = service.findScreenshot(for: screen.name) {
                        ScreenPreviewWindowManager.shared.open(screenName: screen.name, score: screen.score, image: img)
                    }
                }
            }
            if !screen.discrepancies.isEmpty {
                Button("Open Comparison Report") {
                    let img = service.findScreenshot(for: screen.name)
                    ComparisonWindowManager.shared.open(screen: screen, image: img, service: service)
                }
            }
            Divider()
            Button("Copy File Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(screen.filePath, forType: .string)
            }
        }
        .accessibilityLabel("\(screen.name), score \(screen.score.scoreFormatted), \(openIssues) open issues")
    }

    // MARK: - Screen Detail

    private func screenDetail(screen: DriftScreen) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(screen.name)
                        .font(.system(size: 13, weight: .semibold))
                    Text(screen.filePath)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: statusSymbol(screen.score))
                        .font(.system(size: 10))
                    Text(screen.score.scoreFormatted)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(scoreColor(screen.score))

                // Close button
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selectedScreen = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.quaternary)
                }
                .buttonStyle(.plain)
            }

            if screen.discrepancies.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                    Text("All checks passed")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } else {
                // Group by severity
                let grouped = Dictionary(grouping: screen.discrepancies) { $0.severity }
                let order: [Severity] = [.critical, .major, .minor, .cosmetic]

                ForEach(order, id: \.self) { severity in
                    if let items = grouped[severity], !items.isEmpty {
                        ForEach(items) { disc in
                            HStack(spacing: 6) {
                                Text(disc.severity.rawValue)
                                    .font(.system(size: 8, weight: .semibold))
                                    .textCase(.uppercase)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(severityColor(disc.severity).opacity(0.1))
                                    .foregroundStyle(severityColor(disc.severity))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Text(disc.type.rawValue)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.quaternary)

                                Text(disc.element)
                                    .font(.system(size: 11))
                                    .lineLimit(1)

                                Spacer()

                                if disc.status == .open {
                                    Button {
                                        service.fixWithClaude(screen: screen, discrepancy: disc)
                                    } label: {
                                        HStack(spacing: 2) {
                                            Image(systemName: "hammer.fill")
                                                .font(.system(size: 7))
                                            Text("Fix")
                                                .font(.system(size: 8, weight: .medium))
                                        }
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }

                                Image(systemName: disc.status == .fixed ? "checkmark.circle.fill" : disc.status == .wontFix ? "minus.circle.fill" : "exclamationmark.circle")
                                    .font(.system(size: 10))
                                    .foregroundStyle(disc.status == .fixed ? .green : disc.status == .wontFix ? .gray : .orange)
                            }

                            if let hint = disc.fixHint {
                                Text(hint)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.blue.opacity(0.6))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.02))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.04)))
        )
    }

    // MARK: - Onboarding

    private var onboardingState: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.06), .purple.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 110)

                VStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .offset(x: -6, y: -6)
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary.opacity(0.4))
                        }
                        .offset(x: 6, y: 6)
                    }

                    Text("Design compliance for Xcode")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 10) {
                onboardingStep(number: "1", text: "Select your iOS project folder", icon: "folder.fill")
                onboardingStep(number: "2", text: "Run /drift-check in Claude Code", icon: "terminal.fill")
                onboardingStep(number: "3", text: "See compliance scores here", icon: "chart.bar.fill")
            }
            .padding(.horizontal, 28)
        }
    }

    private func onboardingStep(number: String, text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.blue)
                .frame(width: 18, height: 18)
                .background(.blue.opacity(0.1))
                .clipShape(Circle())
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Waiting

    private var waitingState: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.primary.opacity(0.02))
                    .frame(height: 100)

                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                    Text("Waiting for first run")
                        .font(.system(size: 12, weight: .medium))
                    Text("Run /drift-check in Claude Code")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)

            #if DEBUG
            Button("Load Sample Data") {
                service.loadSampleData()
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
            .tint(.blue)
            #endif
        }
    }

    // MARK: - Actions Bar

    private var actionsBar: some View {
        HStack(spacing: 6) {
            Button {
                service.selectProject()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: service.settings.watchedProjectPath.isEmpty ? "folder.badge.plus" : "folder.fill")
                        .font(.system(size: 10))
                    Text(service.settings.watchedProjectPath.isEmpty ? "Select Project" : projectName)
                        .font(.system(size: 11))
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.001)) // invisible hit target
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Spacer()

            if !service.settings.watchedProjectPath.isEmpty {
                ActionButton(icon: "arrow.clockwise", label: nil, help: "Reload reports") {
                    service.loadReports()
                }

                Button {
                    service.runDriftCheck()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 8))
                        Text("Run")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(service.isRunning)
                .help("Run drift-check (Cmd+R)")
            }

            Divider().frame(height: 12)

            AuditMenuButton(service: service)

            ActionButton(icon: "questionmark.circle", label: nil, help: "How to use Drift") {
                HelpWindowManager.shared.open()
            }

            ActionButton(icon: "gear", label: nil, help: "Settings (Cmd+,)") {
                SettingsWindowManager.shared.open(service: service)
            }

            // Quit with confirmation
            if showQuitConfirm {
                HStack(spacing: 4) {
                    Text("Quit?")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                    Button("Yes") {
                        NSApplication.shared.terminate(nil)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.red)
                    .buttonStyle(.plain)
                    Button("No") {
                        withAnimation { showQuitConfirm = false }
                    }
                    .font(.system(size: 10))
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.red.opacity(0.08))
                .clipShape(Capsule())
                .transition(.opacity)
            } else {
                ActionButton(icon: "xmark.circle", label: nil, help: "Quit Drift") {
                    withAnimation(.easeInOut(duration: 0.15)) { showQuitConfirm = true }
                }
                .foregroundStyle(.quaternary)
            }
        }
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Double) -> Color {
        switch score.scoreColor {
        case .pass: return .green
        case .warning: return .yellow
        case .fail: return .red
        }
    }

    private func statusSymbol(_ score: Double) -> String {
        switch score.scoreColor {
        case .pass: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .fail: return "xmark.circle.fill"
        }
    }

    private func statusLabel(_ score: Double) -> String {
        switch score.scoreColor {
        case .pass: return "Passing"
        case .warning: return "Needs review"
        case .fail: return "Failing"
        }
    }

    private func severityColor(_ severity: Severity) -> Color {
        switch severity {
        case .critical: return .red
        case .major: return .orange
        case .minor: return .yellow
        case .cosmetic: return .gray
        }
    }

    private func friendlyError(_ raw: String) -> String {
        if raw.contains("not found") || raw.contains("command not found") {
            return "Claude Code CLI not found. Make sure it's installed."
        }
        if raw.contains("No such file") {
            return "Project path is invalid. Reselect your project."
        }
        return raw.components(separatedBy: "\n").first ?? raw
    }
}

// MARK: - Action Button with hover

struct ActionButton: View {
    let icon: String
    let label: String?
    let help: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                if let label {
                    Text(label)
                        .font(.system(size: 11))
                }
            }
            .padding(4)
            .background(isHovered ? Color.primary.opacity(0.06) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) { isHovered = hovering }
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: RunStatus

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 7))
            Text(label)
                .font(.system(size: 9, weight: .medium))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(bgColor.opacity(0.1))
        .foregroundStyle(bgColor)
        .clipShape(Capsule())
        .accessibilityLabel("Status: \(label)")
    }

    private var label: String {
        switch status {
        case .pass: return "Passed"
        case .acceptable: return "Acceptable"
        case .needsReview: return "Review"
        case .fail: return "Failed"
        case .inProgress: return "Running"
        case .unknown: return "Unknown"
        }
    }

    private var symbol: String {
        switch status {
        case .pass: return "checkmark.circle.fill"
        case .acceptable: return "checkmark.circle"
        case .needsReview: return "exclamationmark.triangle.fill"
        case .fail: return "xmark.circle.fill"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .unknown: return "questionmark.circle"
        }
    }

    private var bgColor: Color {
        switch status {
        case .pass: return .green
        case .acceptable: return .yellow
        case .needsReview: return .orange
        case .fail: return .red
        case .inProgress: return .blue
        case .unknown: return .gray
        }
    }
}
