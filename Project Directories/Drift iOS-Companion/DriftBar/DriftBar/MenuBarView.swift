import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var service: DriftService
    @State private var selectedScreen: DriftScreen?
    @State private var hoveredScreen: String?

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

                        screenGrid(run: run)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 8)

                        if let screen = selectedScreen {
                            screenDetail(screen: screen)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 8)
                        }
                    } else if !service.settings.watchedProjectPath.isEmpty {
                        waitingState
                            .padding(.vertical, 24)
                    } else {
                        onboardingState
                            .padding(.vertical, 16)
                    }
                }
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
            // Logo
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
                .help(error)
            } else if let run = service.latestRun {
                Text(run.summary.overallScore.scoreFormatted)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(scoreColor(run.summary.overallScore))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(scoreColor(run.summary.overallScore).opacity(0.08))
                    .clipShape(Capsule())
            }
        }
    }

    private var projectName: String {
        URL(fileURLWithPath: service.settings.watchedProjectPath).lastPathComponent
    }

    // MARK: - Score Hero

    private func scoreHero(run: DriftRun) -> some View {
        HStack(spacing: 16) {
            // Score ring
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

            // Stats
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 0) {
                    miniStat("\(run.summary.passingScreens)/\(run.summary.totalScreens)", label: "screens", color: .green)
                    Spacer()
                    miniStat("\(run.summary.autoFixed)", label: "fixed", color: .blue)
                    Spacer()
                    miniStat("\(run.summary.totalIterations)", label: "iters", color: .primary)
                }

                // Issues bar
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Screens")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.quaternary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 6)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
            ], spacing: 6) {
                ForEach(run.screens) { screen in
                    screenCard(screen: screen)
                }
            }
        }
    }

    private func screenCard(screen: DriftScreen) -> some View {
        let isSelected = selectedScreen?.name == screen.name
        let isHovered = hoveredScreen == screen.name
        let openIssues = screen.discrepancies.filter { $0.status == .open }.count

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedScreen = isSelected ? nil : screen
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Preview — real screenshot or fallback wireframe
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(isHovered ? 0.05 : 0.025))

                    if let nsImage = service.findScreenshot(for: screen.name) {
                        // Real screenshot
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 80)
                            .clipped()
                    } else {
                        // Wireframe fallback
                        VStack(spacing: 3) {
                            HStack {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.primary.opacity(0.06))
                                    .frame(width: 20, height: 3)
                                Spacer()
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.primary.opacity(0.06))
                                    .frame(width: 14, height: 3)
                            }
                            .padding(.horizontal, 6)
                            .padding(.top, 5)

                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color.primary.opacity(0.04))
                                .frame(height: 4)
                                .padding(.horizontal, 10)

                            VStack(spacing: 3) {
                                ForEach(0..<3, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.primary.opacity(0.03))
                                        .frame(height: 3)
                                        .padding(.trailing, CGFloat(i) * 12)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 2)

                            Spacer()

                            HStack(spacing: 8) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.primary.opacity(0.04))
                                        .frame(width: 4, height: 4)
                                }
                            }
                            .padding(.bottom, 5)
                        }
                    }

                    // Score badge + View button overlay
                    VStack {
                        HStack {
                            // View button (appears on hover)
                            if isHovered, service.findScreenshot(for: screen.name) != nil {
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

                            Text(screen.score.scoreFormatted)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
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
                        Circle()
                            .fill(scoreColor(screen.score))
                            .frame(width: 5, height: 5)
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
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredScreen = hovering ? screen.name : nil
        }
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
                Text(screen.score.scoreFormatted)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(scoreColor(screen.score))
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
                ForEach(screen.discrepancies) { disc in
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

                        Image(systemName: disc.status == .fixed ? "checkmark.circle.fill" : "exclamationmark.circle")
                            .font(.system(size: 10))
                            .foregroundStyle(disc.status == .fixed ? .green : .orange)
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

            Button {
                withAnimation { selectedScreen = nil }
            } label: {
                Text("Close")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
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
            }
            .buttonStyle(.borderless)

            Spacer()

            if !service.settings.watchedProjectPath.isEmpty {
                Button {
                    service.loadReports()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                }
                .buttonStyle(.borderless)
                .help("Reload reports")

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
                .tint(.blue)
            }

            Divider().frame(height: 12)

            Button { openSettings() } label: {
                Image(systemName: "gear")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .help("Settings")

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
            }
            .buttonStyle(.borderless)
            .help("Quit Drift")
        }
    }

    // MARK: - Helpers

    private func openSettings() {
        SettingsWindowManager.shared.open(service: service)
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score.scoreColor {
        case .pass: return .green
        case .warning: return .yellow
        case .fail: return .red
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
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: RunStatus

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(bgColor.opacity(0.1))
            .foregroundStyle(bgColor)
            .clipShape(Capsule())
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
