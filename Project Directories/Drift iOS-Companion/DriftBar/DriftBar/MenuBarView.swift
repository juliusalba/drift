import SwiftUI

struct MenuBarView: View {
    @ObservedObject var service: DriftService
    @State private var selectedScreen: DriftScreen?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if let run = service.latestRun {
                scoreSection(run: run)
                Divider()
                screenList(run: run)
            } else if !service.settings.watchedProjectPath.isEmpty {
                // Project selected but no reports yet
                waitingState
            } else {
                emptyState
            }

            Divider()
            actionsBar
        }
        .frame(width: 340)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Drift")
                    .font(.system(size: 14, weight: .semibold))
                if !service.settings.watchedProjectPath.isEmpty {
                    Text(projectName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    Text("No project selected")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if service.isRunning {
                ProgressView()
                    .controlSize(.small)
                    .padding(.trailing, 4)
                Text(service.currentPhase ?? "Analyzing...")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var projectName: String {
        URL(fileURLWithPath: service.settings.watchedProjectPath).lastPathComponent
    }

    // MARK: - Score

    private func scoreSection(run: DriftRun) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: run.summary.overallScore)
                    .stroke(scoreColor(run.summary.overallScore), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(run.summary.overallScore.scoreFormatted)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(scoreColor(run.summary.overallScore))
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 16) {
                    StatItem(label: "Screens", value: "\(run.summary.totalScreens)", icon: "rectangle.on.rectangle")
                    StatItem(label: "Passing", value: "\(run.summary.passingScreens)", icon: "checkmark.circle", color: .green)
                }
                HStack(spacing: 16) {
                    StatItem(label: "Fixed", value: "\(run.summary.autoFixed)", icon: "wrench", color: .blue)
                    StatItem(label: "Iterations", value: "\(run.summary.totalIterations)", icon: "arrow.triangle.2.circlepath")
                }
            }

            Spacer()

            StatusBadge(status: run.summary.status)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Screen List

    private func screenList(run: DriftRun) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Screens")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(run.summary.passingScreens)/\(run.summary.totalScreens) passing")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(run.screens) { screen in
                        ScreenRow(screen: screen, isSelected: selectedScreen?.name == screen.name)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedScreen = selectedScreen?.name == screen.name ? nil : screen
                                }
                            }
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(maxHeight: 240)

            if let screen = selectedScreen {
                Divider()
                ScreenDetailInline(screen: screen)
            }
        }
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "scope")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text("No project selected")
                .font(.system(size: 13, weight: .medium))
            Text("Click \"Select Project\" below\nto point Drift at your iOS app.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var waitingState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text("No runs yet")
                .font(.system(size: 13, weight: .medium))
            Text("Run /drift-check in Claude Code\nor click \"Run Check\" below.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Actions

    private var actionsBar: some View {
        HStack(spacing: 8) {
            Button {
                service.selectProject()
            } label: {
                Label("Select Project", systemImage: "folder")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)

            Spacer()

            if !service.settings.watchedProjectPath.isEmpty {
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

            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Double) -> Color {
        switch score.scoreColor {
        case .pass: return .green
        case .warning: return .yellow
        case .fail: return .red
        }
    }
}

// MARK: - Subviews

struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    var color: Color = .primary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(color == .primary ? .primary : color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}

struct StatusBadge: View {
    let status: RunStatus

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bgColor.opacity(0.15))
            .foregroundStyle(bgColor)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(bgColor.opacity(0.3), lineWidth: 0.5))
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
