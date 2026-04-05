import Foundation
import Combine
import AppKit

@MainActor
final class DriftService: ObservableObject {
    @Published var latestRun: DriftRun?
    @Published var runHistory: [RunIndexEntry] = []
    @Published var isRunning = false
    @Published var currentPhase: String?
    @Published var settings = DriftSettings()

    private let settingsURL: URL
    private var reportsDir: URL?
    private var buildWatcher: BuildWatcher?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let driftDir = appSupport.appendingPathComponent("DriftBar", isDirectory: true)
        try? FileManager.default.createDirectory(at: driftDir, withIntermediateDirectories: true)
        settingsURL = driftDir.appendingPathComponent("settings.json")
        loadSettings()

        // Restore project path from saved settings
        if !settings.watchedProjectPath.isEmpty {
            reportsDir = URL(fileURLWithPath: settings.watchedProjectPath)
                .appendingPathComponent("drift-reports", isDirectory: true)
            loadReports()
        }
    }

    // MARK: - Watching

    func startWatching() {
        guard buildWatcher == nil else { return }

        buildWatcher = BuildWatcher(
            onBuildCompleted: { [weak self] in
                Task { @MainActor in
                    guard let self, self.settings.autoRunOnBuild else { return }
                    self.runDriftCheck()
                }
            },
            onReportsChanged: { [weak self] in
                Task { @MainActor in
                    self?.loadReports()
                }
            }
        )

        buildWatcher?.watchDerivedData()

        if !settings.watchedProjectPath.isEmpty {
            buildWatcher?.watchReports(at: settings.watchedProjectPath)
        }
    }

    // MARK: - Settings

    func loadSettings() {
        guard let data = try? Data(contentsOf: settingsURL),
              let loaded = try? JSONDecoder().decode(DriftSettings.self, from: data) else { return }
        settings = loaded
    }

    func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: settingsURL)
    }

    // MARK: - Project Selection

    func selectProject() {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select your iOS project folder"
        panel.prompt = "Select"
        panel.level = .floating

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                self?.setProjectPath(url.path)
            }
        }
    }

    func setProjectPath(_ path: String) {
        settings.watchedProjectPath = path
        reportsDir = URL(fileURLWithPath: path).appendingPathComponent("drift-reports", isDirectory: true)
        saveSettings()
        loadReports()
        buildWatcher?.watchReports(at: path)
    }

    // MARK: - Reports

    func loadReports() {
        guard let dir = reportsDir else { return }

        let indexURL = dir.appendingPathComponent("index.json")
        if let data = try? Data(contentsOf: indexURL),
           let index = try? JSONDecoder().decode(RunIndex.self, from: data) {
            runHistory = index.runs
        } else {
            scanForRuns(in: dir)
        }

        if let latest = runHistory.sorted(by: { $0.timestamp > $1.timestamp }).first {
            loadRun(id: latest.id)
        }
    }

    private func scanForRuns(in dir: URL) {
        guard let entries = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            runHistory = []
            return
        }

        var found: [RunIndexEntry] = []
        for entry in entries where entry.lastPathComponent.hasPrefix("run-") {
            let dataURL = entry.appendingPathComponent("data.json")
            guard let data = try? Data(contentsOf: dataURL),
                  let run = try? JSONDecoder().decode(DriftRun.self, from: data) else { continue }
            found.append(RunIndexEntry(
                id: run.id,
                projectName: run.projectName,
                timestamp: run.timestamp,
                overallScore: run.summary.overallScore,
                totalScreens: run.summary.totalScreens,
                passingScreens: run.summary.passingScreens,
                status: run.summary.status.rawValue,
                iterations: run.summary.totalIterations
            ))
        }
        runHistory = found.sorted { $0.timestamp > $1.timestamp }
    }

    func loadRun(id: String) {
        guard let dir = reportsDir else { return }
        let paths = [
            dir.appendingPathComponent(id).appendingPathComponent("data.json"),
            dir.appendingPathComponent("run-\(id)").appendingPathComponent("data.json"),
        ]
        for path in paths {
            if let data = try? Data(contentsOf: path),
               let run = try? JSONDecoder().decode(DriftRun.self, from: data) {
                latestRun = run
                return
            }
        }
    }

    // MARK: - Sample Data (for testing UI without real reports)

    func loadSampleData() {
        latestRun = DriftRun(
            id: "run-001",
            projectName: settings.watchedProjectPath.isEmpty
                ? "SampleApp"
                : URL(fileURLWithPath: settings.watchedProjectPath).lastPathComponent,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            summary: RunSummary(
                overallScore: 0.87,
                totalScreens: 6,
                passingScreens: 4,
                reviewScreens: 2,
                criticalIssues: 0,
                majorIssues: 3,
                autoFixed: 5,
                totalIterations: 3,
                status: .acceptable
            ),
            screens: [
                DriftScreen(name: "HomeView", score: 0.95, filePath: "Sources/Views/HomeView.swift", discrepancies: []),
                DriftScreen(name: "ProfileView", score: 0.92, filePath: "Sources/Views/ProfileView.swift", discrepancies: []),
                DriftScreen(name: "SettingsView", score: 0.91, filePath: "Sources/Views/SettingsView.swift", discrepancies: []),
                DriftScreen(name: "LoginView", score: 0.78, filePath: "Sources/Views/LoginView.swift", discrepancies: [
                    Discrepancy(type: .color, severity: .major, element: "CTA Button", expected: "#377CC8", actual: "#3A7BC8", fixHint: ".foregroundColor(Color(hex: \"#377CC8\"))", status: .fixed, confidence: 0.85),
                    Discrepancy(type: .spacing, severity: .major, element: "Header padding", expected: "16pt", actual: "12pt", fixHint: ".padding(.top, 16)", status: .fixed, confidence: 0.9),
                    Discrepancy(type: .typography, severity: .minor, element: "Subtitle font", expected: "SF Pro Medium 14", actual: "SF Pro Regular 14", fixHint: ".font(.system(size: 14, weight: .medium))", status: .open, confidence: 0.72),
                ]),
                DriftScreen(name: "OnboardingView", score: 0.72, filePath: "Sources/Views/OnboardingView.swift", discrepancies: [
                    Discrepancy(type: .layout, severity: .major, element: "Card stack", expected: "Horizontal scroll", actual: "Vertical list", fixHint: nil, status: .open, confidence: 0.65),
                    Discrepancy(type: .spacing, severity: .minor, element: "Bottom CTA margin", expected: "24pt", actual: "20pt", fixHint: ".padding(.bottom, 24)", status: .fixed, confidence: 0.88),
                ]),
            ],
            iterations: [
                Iteration(number: 1, score: 0.71, delta: 0, fixed: 0, regressions: 0, timestamp: nil),
                Iteration(number: 2, score: 0.82, delta: 0.11, fixed: 3, regressions: 0, timestamp: nil),
                Iteration(number: 3, score: 0.87, delta: 0.05, fixed: 2, regressions: 0, timestamp: nil),
            ]
        )
    }

    // MARK: - Run Drift Check

    func runDriftCheck() {
        guard !isRunning else { return }
        guard !settings.watchedProjectPath.isEmpty else { return }

        isRunning = true
        currentPhase = "Starting analysis..."

        let projectPath = settings.watchedProjectPath

        Task.detached {
            // Use login shell to inherit user's PATH (so `claude` CLI is findable)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-l", "-c", "cd \"\(projectPath)\" && claude -p \"Run /drift-check on this project\""]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                // CLI not available
            }

            await MainActor.run { [weak self] in
                self?.isRunning = false
                self?.currentPhase = nil
                self?.loadReports()
            }
        }
    }
}
