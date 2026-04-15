import Foundation

/// Builds an iOS project, boots a simulator, launches the app, and captures a screenshot.
/// Opt-in: controlled by `drift.capture.json` at the project root:
/// ```
/// { "scheme": "MyApp", "bundleId": "com.me.myapp",
///   "device": "iPhone 17", "launchWaitSeconds": 3 }
/// ```
enum SimulatorCapture {

    struct Config: Decodable {
        let scheme: String
        let bundleId: String
        let device: String?
        let launchWaitSeconds: Double?

        var deviceName: String { device ?? "iPhone 17" }
        var waitSeconds: Double { launchWaitSeconds ?? 3.0 }
    }

    struct Result {
        let imageURL: URL
        let device: String
        let elapsed: TimeInterval
    }

    enum Failure: Error, LocalizedError {
        case notConfigured
        case xcodebuildFailed(String)
        case simctlFailed(String)
        case appNotFound
        var errorDescription: String? {
            switch self {
            case .notConfigured:     "drift.capture.json not found — skipping simulator capture."
            case .xcodebuildFailed(let s): "xcodebuild failed: \(s.prefix(200))"
            case .simctlFailed(let s):     "simctl failed: \(s.prefix(200))"
            case .appNotFound:       ".app not produced by build"
            }
        }
    }

    // MARK: - Public

    static func loadConfig(in projectDir: URL) -> Config? {
        let url = projectDir.appendingPathComponent("drift.capture.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Config.self, from: data)
    }

    /// Builds + boots + launches + screenshots. Returns the screenshot URL.
    static func captureScreenshot(
        config: Config,
        projectDir: URL,
        outputURL: URL,
        onLog: @escaping (String) -> Void
    ) async throws -> Result {
        let start = Date()
        onLog("▶ building \(config.scheme) for \(config.deviceName)…\n")

        let derived = projectDir.appendingPathComponent(".drift-cache/DerivedData", isDirectory: true)
        try? FileManager.default.createDirectory(at: derived, withIntermediateDirectories: true)

        let project = try locateXcodeProject(in: projectDir)
        let buildCmd = [
            "xcodebuild",
            project.isWorkspace ? "-workspace" : "-project", project.url.path,
            "-scheme", config.scheme,
            "-destination", "platform=iOS Simulator,name=\(config.deviceName)",
            "-derivedDataPath", derived.path,
            "-configuration", "Debug",
            "build"
        ]
        let buildResult = runShell(buildCmd, cwd: projectDir)
        onLog(tail(buildResult.output, 40))
        guard buildResult.exitCode == 0 else {
            throw Failure.xcodebuildFailed(buildResult.output)
        }

        // Find .app
        let appURL = try findBuiltApp(in: derived, scheme: config.scheme)
        onLog("  app: \(appURL.lastPathComponent)\n")

        // Boot device (idempotent — ignore "already booted")
        _ = runShell(["xcrun", "simctl", "boot", config.deviceName])
        _ = runShell(["open", "-a", "Simulator"]) // bring the Simulator app up
        try await Task.sleep(nanoseconds: 1_200_000_000)

        // Install
        let install = runShell(["xcrun", "simctl", "install", "booted", appURL.path])
        guard install.exitCode == 0 else { throw Failure.simctlFailed(install.output) }

        // Launch
        let launch = runShell(["xcrun", "simctl", "launch", "booted", config.bundleId])
        guard launch.exitCode == 0 else { throw Failure.simctlFailed(launch.output) }

        // Wait for first render
        let ns = UInt64(max(0.5, config.waitSeconds) * 1_000_000_000)
        try await Task.sleep(nanoseconds: ns)

        // Screenshot
        try? FileManager.default.removeItem(at: outputURL)
        try? FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let shot = runShell(["xcrun", "simctl", "io", "booted", "screenshot", outputURL.path])
        guard shot.exitCode == 0, FileManager.default.fileExists(atPath: outputURL.path) else {
            throw Failure.simctlFailed(shot.output)
        }

        return Result(
            imageURL: outputURL,
            device: config.deviceName,
            elapsed: Date().timeIntervalSince(start)
        )
    }

    // MARK: - Helpers

    private struct ProjectRef { let url: URL; let isWorkspace: Bool }

    private static func locateXcodeProject(in dir: URL) throws -> ProjectRef {
        let items = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        if let ws = items.first(where: { $0.pathExtension == "xcworkspace" }) {
            return ProjectRef(url: ws, isWorkspace: true)
        }
        if let pr = items.first(where: { $0.pathExtension == "xcodeproj" }) {
            return ProjectRef(url: pr, isWorkspace: false)
        }
        // One level deep
        for sub in items where (try? sub.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            let nested = (try? FileManager.default.contentsOfDirectory(at: sub, includingPropertiesForKeys: nil)) ?? []
            if let ws = nested.first(where: { $0.pathExtension == "xcworkspace" }) {
                return ProjectRef(url: ws, isWorkspace: true)
            }
            if let pr = nested.first(where: { $0.pathExtension == "xcodeproj" }) {
                return ProjectRef(url: pr, isWorkspace: false)
            }
        }
        throw Failure.xcodebuildFailed("no .xcodeproj / .xcworkspace found near \(dir.path)")
    }

    private static func findBuiltApp(in derivedData: URL, scheme: String) throws -> URL {
        let productsRoot = derivedData.appendingPathComponent("Build/Products/Debug-iphonesimulator", isDirectory: true)
        let candidates = (try? FileManager.default.contentsOfDirectory(at: productsRoot, includingPropertiesForKeys: nil)) ?? []
        if let exact = candidates.first(where: { $0.pathExtension == "app" && $0.deletingPathExtension().lastPathComponent == scheme }) {
            return exact
        }
        if let any = candidates.first(where: { $0.pathExtension == "app" }) { return any }
        throw Failure.appNotFound
    }

    // MARK: - Shell

    private struct ShellResult { let exitCode: Int32; let output: String }

    private static func runShell(_ args: [String], cwd: URL? = nil) -> ShellResult {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = args
        if let cwd { p.currentDirectoryURL = cwd }
        let out = Pipe(); p.standardOutput = out; p.standardError = out
        do { try p.run() } catch {
            return ShellResult(exitCode: -1, output: "launch failed: \(error.localizedDescription)")
        }
        p.waitUntilExit()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        return ShellResult(exitCode: p.terminationStatus, output: String(data: data, encoding: .utf8) ?? "")
    }

    private static func tail(_ s: String, _ n: Int) -> String {
        let lines = s.components(separatedBy: "\n")
        return "  " + lines.suffix(n).joined(separator: "\n  ") + "\n"
    }
}
