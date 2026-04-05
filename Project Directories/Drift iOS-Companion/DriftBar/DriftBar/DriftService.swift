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

    private func loadSettings() {
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
        // NSOpenPanel needs the app to be active to show properly from menu bar
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select your iOS project folder"
        panel.prompt = "Select"
        panel.level = .floating // Ensure it appears above everything

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

        // Try index first
        let indexURL = dir.appendingPathComponent("index.json")
        if let data = try? Data(contentsOf: indexURL),
           let index = try? JSONDecoder().decode(RunIndex.self, from: data) {
            runHistory = index.runs
        } else {
            scanForRuns(in: dir)
        }

        // Load latest run
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

    // MARK: - Run Drift Check

    func runDriftCheck() {
        guard !isRunning else { return }
        guard !settings.watchedProjectPath.isEmpty else { return }

        isRunning = true
        currentPhase = "Starting analysis..."

        let projectPath = settings.watchedProjectPath

        Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["claude", "-p", "Run /drift-check on this project"]
            process.currentDirectoryURL = URL(fileURLWithPath: projectPath)

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
