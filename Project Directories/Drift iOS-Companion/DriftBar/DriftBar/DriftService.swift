import Foundation
import Combine
import AppKit

@MainActor
final class DriftService: ObservableObject {
    @Published var latestRun: DriftRun?
    @Published var runHistory: [RunIndexEntry] = []
    @Published var isRunning = false
    @Published var currentPhase: String?
    @Published var lastError: String?
    @Published var settings = DriftSettings()

    private let settingsURL: URL
    private var reportsDir: URL?
    private var buildWatcher: BuildWatcher?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? FileManager.default.temporaryDirectory
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
        // Validate path exists and is a directory
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
            lastError = "Invalid project path: \(path)"
            return
        }

        settings.watchedProjectPath = path
        reportsDir = URL(fileURLWithPath: path).appendingPathComponent("drift-reports", isDirectory: true)
        clearScreenshotCache()
        saveSettings()
        loadReports()
        buildWatcher?.watchReports(at: path)
    }

    // MARK: - Screenshot Discovery

    // Screenshot cache to avoid repeated disk I/O
    private var screenshotCache: [String: NSImage?] = [:]

    /// Scan the project directory for simulator screenshots and match them to screens.
    /// Results are cached per screen name.
    func findScreenshot(for screenName: String) -> NSImage? {
        if let cached = screenshotCache[screenName] {
            return cached
        }

        guard !settings.watchedProjectPath.isEmpty else { return nil }
        let projectDir = settings.watchedProjectPath

        let candidates = [
            "drift-reports/\(latestRun?.id ?? "")/screens/\(screenName).png",
            "drift-reports/\(latestRun?.id ?? "")/screens/\(screenName.lowercased()).png",
            "sim_\(screenName.lowercased().replacingOccurrences(of: "view", with: "")).png",
            "sim_\(screenName.lowercased()).png",
            "\(screenName).png",
            "\(screenName.lowercased()).png",
            "Screenshots/\(screenName).png",
        ]

        for candidate in candidates {
            let path = (projectDir as NSString).appendingPathComponent(candidate)
            if FileManager.default.fileExists(atPath: path),
               let img = NSImage(contentsOfFile: path) {
                screenshotCache[screenName] = img
                return img
            }
        }

        screenshotCache[screenName] = nil
        return nil
    }

    /// Clear screenshot cache (call when project changes or reports reload).
    func clearScreenshotCache() {
        screenshotCache.removeAll()
    }

    /// Get all screenshot files from the project directory.
    func allScreenshotPaths() -> [String: String] {
        guard !settings.watchedProjectPath.isEmpty else { return [:] }
        let dir = settings.watchedProjectPath
        var result: [String: String] = [:]

        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return [:] }
        for file in files where file.hasSuffix(".png") && file.hasPrefix("sim_") {
            // "sim_home.png" → key "home"
            let name = file
                .replacingOccurrences(of: "sim_", with: "")
                .replacingOccurrences(of: ".png", with: "")
            result[name] = (dir as NSString).appendingPathComponent(file)
        }

        return result
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
                DriftScreen(name: "HomeView", score: 0.95, filePath: "TLSCompanion/Views/HomeView.swift", discrepancies: []),
                DriftScreen(name: "LibraryView", score: 0.92, filePath: "TLSCompanion/Views/LibraryView.swift", discrepancies: []),
                DriftScreen(name: "SettingsView", score: 0.91, filePath: "TLSCompanion/Views/SettingsView.swift", discrepancies: []),
                DriftScreen(name: "OnboardingView", score: 0.78, filePath: "TLSCompanion/Views/OnboardingView.swift", discrepancies: [
                    Discrepancy(type: .color, severity: .major, element: "CTA Button", expected: "#377CC8", actual: "#3A7BC8", fixHint: ".foregroundColor(Color(hex: \"#377CC8\"))", status: .fixed, confidence: 0.85),
                    Discrepancy(type: .spacing, severity: .major, element: "Header padding", expected: "16pt", actual: "12pt", fixHint: ".padding(.top, 16)", status: .fixed, confidence: 0.9),
                    Discrepancy(type: .typography, severity: .minor, element: "Subtitle font", expected: "SF Pro Medium 14", actual: "SF Pro Regular 14", fixHint: ".font(.system(size: 14, weight: .medium))", status: .open, confidence: 0.72),
                ]),
                DriftScreen(name: "ShopView", score: 0.72, filePath: "TLSCompanion/Views/ShopView.swift", discrepancies: [
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

    // MARK: - Fix Actions

    /// Copy a fix hint code snippet to clipboard.
    func copyFix(_ discrepancy: Discrepancy) {
        guard let hint = discrepancy.fixHint else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hint, forType: .string)
    }

    /// Open Claude Code with a prompt to fix a specific discrepancy.
    func fixWithClaude(screen: DriftScreen, discrepancy: Discrepancy) {
        let projectPath = settings.watchedProjectPath
        guard !projectPath.isEmpty else {
            lastError = "No project selected"
            return
        }

        var prompt = "In the file \(screen.filePath), fix the \(discrepancy.type.rawValue) issue on the \(discrepancy.element) element. "
        prompt += "Expected: \(discrepancy.expected). Actual: \(discrepancy.actual). "
        if let hint = discrepancy.fixHint {
            prompt += "Suggested fix: \(hint). "
        }
        prompt += "Only change the visual property, don't modify any business logic."

        openClaudeWithPrompt(prompt, in: projectPath)
    }

    /// Fix all open issues on a screen via Claude Code.
    func fixAllWithClaude(screen: DriftScreen) {
        let projectPath = settings.watchedProjectPath
        guard !projectPath.isEmpty else { return }

        let openIssues = screen.discrepancies.filter { $0.status == .open }
        guard !openIssues.isEmpty else { return }

        var prompt = "In \(screen.filePath), fix these design issues (visual properties only, no business logic changes):\n"
        for (i, disc) in openIssues.enumerated() {
            prompt += "\(i + 1). \(disc.type.rawValue) on \(disc.element): expected \(disc.expected), actual \(disc.actual)"
            if let hint = disc.fixHint {
                prompt += " — suggested: \(hint)"
            }
            prompt += "\n"
        }

        openClaudeWithPrompt(prompt, in: projectPath)
    }

    /// Write prompt to a temp file and open Claude Code via Terminal to avoid escaping issues.
    private func openClaudeWithPrompt(_ prompt: String, in projectPath: String) {
        // Write prompt to a temp file to avoid shell escaping issues
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("drift_fix_prompt.txt")
        do {
            try prompt.write(to: tmpFile, atomically: true, encoding: .utf8)
        } catch {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(prompt, forType: .string)
            lastError = "Fix prompt copied to clipboard."
            return
        }

        let shellCmd = "cd '\(projectPath)' && claude \"$(cat '\(tmpFile.path)')\""

        let appleScript = """
        tell application "Terminal"
            activate
            do script "\(shellCmd.replacingOccurrences(of: "\"", with: "\\\""))"
        end tell
        """

        var error: NSDictionary?
        if let scriptObj = NSAppleScript(source: appleScript) {
            scriptObj.executeAndReturnError(&error)
            if error != nil {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(prompt, forType: .string)
                lastError = "Couldn't open Terminal. Fix prompt copied to clipboard."
            }
        }
    }

    // MARK: - Run Drift Check

    func runDriftCheck() {
        guard !isRunning else { return }
        guard !settings.watchedProjectPath.isEmpty else { return }

        // Try to open Claude Code in the project directory instead of running headlessly.
        // The --print flag has compatibility issues, so we open Claude Code interactively.
        let projectPath = settings.watchedProjectPath

        // Copy the command to clipboard for easy pasting
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("/drift-check", forType: .string)

        // Try opening Claude Code (the desktop app) with the project
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "cd \"\(projectPath)\" && open -a 'Claude' . 2>/dev/null || claude 2>/dev/null &"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            currentPhase = "/drift-check copied to clipboard"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.currentPhase = nil
            }
        } catch {
            lastError = "Open Claude Code and run /drift-check in your project"
        }
    }
}
