import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var service: DriftService
    @State private var selectedScreen: DriftScreen?
    @State private var hoveredScreen: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if let run = service.latestRun {
                scoreHero(run: run)
                Divider()
                screenGrid(run: run)
                if let screen = selectedScreen {
                    Divider()
                    screenDetail(screen: screen)
                }
            } else if !service.settings.watchedProjectPath.isEmpty {
                waitingState
            } else {
                onboardingState
            }

            Divider()
            actionsBar
        }
        .frame(width: 420, height: 580)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            // App icon
            Image("MenuBarIcon")
                .resizable()
                .frame(width: 20, height: 20)
                .opacity(0.8)

            VStack(alignment: .leading, spacing: 1) {
                Text("Drift")
                    .font(.system(size: 13, weight: .semibold))
                if !service.settings.watchedProjectPath.isEmpty {
                    Text(projectName)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if service.isRunning {
                HStack(spacing: 6) {
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
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                        Text("Error")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help(error)
            } else if let run = service.latestRun {
                // Mini score pill in header
                Text(run.summary.overallScore.scoreFormatted)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(scoreColor(run.summary.overallScore))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(scoreColor(run.summary.overallScore).opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var projectName: String {
        URL(fileURLWithPath: service.settings.watchedProjectPath).lastPathComponent
    }

    // MARK: - Score Hero

    private func scoreHero(run: DriftRun) -> some View {
        HStack(spacing: 20) {
            // Large score ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 5)
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
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(scoreColor(run.summary.overallScore))
                    Text("score")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                }
            }
            .frame(width: 72, height: 72)

            // Stats grid
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 20) {
                    statCard(value: "\(run.summary.totalScreens)", label: "Screens", icon: "rectangle.on.rectangle", color: .primary)
                    statCard(value: "\(run.summary.passingScreens)", label: "Passing", icon: "checkmark.circle.fill", color: .green, isAccent: true)
                    statCard(value: "\(run.summary.autoFixed)", label: "Fixed", icon: "wrench.and.screwdriver.fill", color: .blue, isAccent: true)
                }
                HStack(spacing: 20) {
                    statCard(value: "\(run.summary.totalIterations)", label: "Iterations", icon: "arrow.triangle.2.circlepath", color: .primary)
                    statCard(value: "\(run.summary.criticalIssues + run.summary.majorIssues)", label: "Issues", icon: "exclamationmark.triangle.fill", color: run.summary.criticalIssues > 0 ? .red : .orange, isAccent: true)
                    StatusBadge(status: run.summary.status)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func statCard(value: String, label: String, icon: String, color: Color, isAccent: Bool = false) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(isAccent ? color.opacity(0.7) : Color.gray)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(isAccent ? color : nil)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Screen Grid (visual cards instead of a list)

    private func screenGrid(run: DriftRun) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Screens")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(run.summary.passingScreens)/\(run.summary.totalScreens) passing")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6),
                ], spacing: 6) {
                    ForEach(run.screens) { screen in
                        screenCard(screen: screen)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 320)
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
                // Preview area (mock phone screen)
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.03))

                    VStack(spacing: 3) {
                        // Mock status bar
                        HStack {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.primary.opacity(0.08))
                                .frame(width: 20, height: 3)
                            Spacer()
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.primary.opacity(0.08))
                                .frame(width: 14, height: 3)
                        }
                        .padding(.horizontal, 6)
                        .padding(.top, 5)

                        // Mock nav bar
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.primary.opacity(0.06))
                            .frame(height: 4)
                            .padding(.horizontal, 10)

                        // Mock content lines
                        VStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.primary.opacity(0.04))
                                    .frame(height: 3)
                                    .padding(.trailing, CGFloat(i) * 12)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 2)

                        Spacer()

                        // Mock bottom bar
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(Color.primary.opacity(0.05))
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .padding(.bottom, 5)
                    }

                    // Score overlay
                    VStack {
                        HStack {
                            Spacer()
                            Text(screen.score.scoreFormatted)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(scoreColor(screen.score))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .padding(5)
                        Spacer()
                    }
                }
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Info area
                VStack(alignment: .leading, spacing: 3) {
                    Text(screen.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
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
                .padding(.top, 6)
                .padding(.bottom, 2)
            }
            .padding(8)
            .frame(height: 130)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected
                        ? Color.primary.opacity(0.08)
                        : isHovered
                            ? Color.primary.opacity(0.04)
                            : Color.primary.opacity(0.02)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected
                            ? scoreColor(screen.score).opacity(0.4)
                            : Color.primary.opacity(0.06),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredScreen = hovering ? screen.name : nil
        }
    }

    // MARK: - Screen Detail (expanded)

    private func screenDetail(screen: DriftScreen) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
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
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                    Text("All checks passed")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                // Discrepancy list
                ForEach(screen.discrepancies) { disc in
                    HStack(spacing: 6) {
                        // Severity pill
                        Text(disc.severity.rawValue)
                            .font(.system(size: 8, weight: .semibold))
                            .textCase(.uppercase)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(severityColor(disc.severity).opacity(0.12))
                            .foregroundStyle(severityColor(disc.severity))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        // Type tag
                        Text(disc.type.rawValue)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.tertiary)

                        // Element
                        Text(disc.element)
                            .font(.system(size: 11))
                            .lineLimit(1)

                        Spacer()

                        // Status
                        Image(systemName: disc.status == .fixed ? "checkmark.circle.fill" : disc.status == .wontFix ? "minus.circle.fill" : "exclamationmark.circle")
                            .font(.system(size: 10))
                            .foregroundStyle(disc.status == .fixed ? .green : disc.status == .wontFix ? .gray : .orange)
                    }

                    // Fix hint preview
                    if let hint = disc.fixHint {
                        Text(hint)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.blue.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(.leading, 20)
                    }
                }
            }

            // Close button
            Button {
                withAnimation { selectedScreen = nil }
            } label: {
                Text("Close")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.02))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Onboarding (first launch)

    private var onboardingState: some View {
        VStack(spacing: 14) {
            // Hero illustration area
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.05))
                    .frame(height: 120)

                VStack(spacing: 8) {
                    ZStack {
                        // Back square (design)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .offset(x: -6, y: -6)

                        // Front square (build) with checkmark
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary.opacity(0.5))
                        }
                        .offset(x: 6, y: 6)
                    }

                    Text("Design compliance for Xcode")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)

            // Steps
            VStack(alignment: .leading, spacing: 10) {
                onboardingStep(number: 1, text: "Select your iOS project folder", icon: "folder.fill")
                onboardingStep(number: 2, text: "Run /drift-check in Claude Code", icon: "terminal.fill")
                onboardingStep(number: 3, text: "See compliance scores here", icon: "chart.bar.fill")
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 20)
    }

    private func onboardingStep(number: Int, text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(.blue.opacity(0.7))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Waiting State

    private var waitingState: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary.opacity(0.03))
                    .frame(height: 100)

                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                    Text("Waiting for first run")
                        .font(.system(size: 12, weight: .medium))
                    Text("Run /drift-check in Claude Code\nor click Run Check below")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
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
        .padding(.vertical, 16)
    }

    // MARK: - Actions Bar

    private var actionsBar: some View {
        HStack(spacing: 8) {
            // Project button
            Button {
                service.selectProject()
            } label: {
                Label(
                    service.settings.watchedProjectPath.isEmpty ? "Select Project" : projectName,
                    systemImage: service.settings.watchedProjectPath.isEmpty ? "folder.badge.plus" : "folder.fill"
                )
                .font(.system(size: 11))
                .lineLimit(1)
            }
            .buttonStyle(.borderless)

            Spacer()

            if !service.settings.watchedProjectPath.isEmpty {
                // Refresh
                Button {
                    service.loadReports()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .help("Reload reports")

                // Run check
                Button {
                    service.runDriftCheck()
                } label: {
                    Label("Run Check", systemImage: "play.fill")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderless)
                .disabled(service.isRunning)
                .tint(.blue)

                Divider()
                    .frame(height: 12)
            }

            // Settings
            Button {
                openSettings()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Settings")

            // Quit
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(.quaternary)
            }
            .buttonStyle(.borderless)
            .help("Quit Drift")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
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

// MARK: - Subviews

struct StatusBadge: View {
    let status: RunStatus

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bgColor.opacity(0.12))
            .foregroundStyle(bgColor)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(bgColor.opacity(0.2), lineWidth: 0.5))
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
