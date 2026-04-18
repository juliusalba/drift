import Foundation
import AppKit

/// Drives the booted iOS simulator by enumerating its accessibility tree via
/// `idb describe-ui`, tapping the most distinct-looking elements with
/// `idb ui tap`, and capturing a screenshot after each tap — giving the UI
/// a scrolling flipbook of "the app walking itself."
///
/// Requires Facebook's `idb` (iOS Debug Bridge) on PATH:
///     brew tap facebook/fb
///     brew install idb-companion
///     pipx install fb-idb       # provides the `idb` CLI
///
/// If `idb` isn't available, `start()` transitions to `.unavailable` and the
/// UI surfaces the install instructions. This module never shells out on the
/// main actor — all idb calls are on Task.detached.
@MainActor
final class AutoExplorer: ObservableObject {

    enum State: Equatable {
        case idle
        case unavailable(reason: String)
        case waitingForSimulator
        case exploring
        case finished
        case failed(String)
    }

    struct Step: Identifiable, Equatable {
        let id = UUID()
        let index: Int
        let at: Date
        let action: String           // "tap @ (120, 340)" or "describe-ui"
        let targetLabel: String?     // accessibility label of the tapped element
        let screenshotPath: URL?     // post-action frame, saved to disk
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var steps: [Step] = []
    @Published private(set) var udid: String?
    @Published private(set) var explorationDir: URL?

    private var isCancelled: Bool = false
    private var maxSteps: Int = 20
    private var tapDelayMs: UInt64 = 700

    // MARK: - Lifecycle

    /// Kick off exploration. If idb isn't installed, flips to `.unavailable`
    /// and records why. If no simulator is booted, waits for one to come up
    /// (same pattern as SessionRecorder) before actually exploring.
    func start(projectDirectory: URL, maxSteps: Int = 20) {
        guard state == .idle || state.isFinished else { return }
        self.isCancelled = false
        self.maxSteps = maxSteps
        self.steps = []

        let stamp = Self.timestampString()
        let dir = projectDirectory
            .appendingPathComponent("drift-reports", isDirectory: true)
            .appendingPathComponent("exploration", isDirectory: true)
            .appendingPathComponent(stamp, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.explorationDir = dir

        self.state = .waitingForSimulator

        Task.detached { [weak self] in
            // 1. Check idb is on PATH.
            guard let idb = Self.findIDB() else {
                await MainActor.run { [weak self] in
                    self?.state = .unavailable(reason: """
                        idb CLI not found. Install with:
                          brew tap facebook/fb && brew install idb-companion
                          pipx install fb-idb
                        """)
                }
                return
            }
            // 2. Find a booted simulator (poll up to ~30s).
            var udidOut: String?
            for _ in 0..<30 {
                if let found = Self.findBootedUDID() { udidOut = found; break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let cancelled = await MainActor.run { [weak self] in self?.isCancelled ?? true }
                if cancelled { return }
            }
            guard let bootedUDID = udidOut else {
                await MainActor.run { [weak self] in
                    self?.state = .failed("No booted simulator appeared after 30s.")
                }
                return
            }
            await MainActor.run { [weak self] in
                self?.udid = bootedUDID
                self?.state = .exploring
            }

            // 3. Run the exploration loop.
            await self?.explorationLoop(idb: idb, udid: bootedUDID, dir: dir)
        }
    }

    func stop() {
        isCancelled = true
        if state == .exploring || state == .waitingForSimulator {
            state = .finished
        }
    }

    // MARK: - Loop

    nonisolated private func explorationLoop(idb: String, udid: String, dir: URL) async {
        var stepIndex = 0
        var alreadyTapped: Set<String> = []

        while true {
            let cancelled = await MainActor.run { [weak self] in self?.isCancelled ?? true }
            if cancelled { break }
            if await self.shouldStop(at: stepIndex) { break }

            // Describe the accessibility tree.
            guard let elements = await Self.describeUI(idb: idb, udid: udid) else {
                await self.appendStep(Step(
                    index: stepIndex,
                    at: Date(),
                    action: "describe-ui failed",
                    targetLabel: nil,
                    screenshotPath: nil
                ))
                break
            }

            // Pick the next tappable element we haven't exercised yet.
            let candidate = Self.nextCandidate(from: elements, skipping: alreadyTapped)
            guard let target = candidate else {
                // Dead end — try a back-nav swipe from left edge.
                _ = await Self.swipeBack(idb: idb, udid: udid)
                let frame = await Self.captureFrame(udid: udid, dir: dir, index: stepIndex)
                await self.appendStep(Step(
                    index: stepIndex,
                    at: Date(),
                    action: "swipe-back (no new targets)",
                    targetLabel: nil,
                    screenshotPath: frame
                ))
                stepIndex += 1
                try? await Task.sleep(nanoseconds: UInt64(self.tapDelayMs) * 1_000_000)
                continue
            }

            alreadyTapped.insert(target.fingerprint)
            let tapStatus = await Self.tap(idb: idb, udid: udid, x: target.centerX, y: target.centerY)
            try? await Task.sleep(nanoseconds: UInt64(self.tapDelayMs) * 1_000_000)
            let frame = await Self.captureFrame(udid: udid, dir: dir, index: stepIndex)

            let action: String
            if tapStatus == 0 {
                action = "tap @ (\(Int(target.centerX)), \(Int(target.centerY)))"
            } else {
                action = "tap failed (idb exit \(tapStatus)) @ (\(Int(target.centerX)), \(Int(target.centerY)))"
            }

            await self.appendStep(Step(
                index: stepIndex,
                at: Date(),
                action: action,
                targetLabel: target.label,
                screenshotPath: frame
            ))
            stepIndex += 1
        }

        await MainActor.run { [weak self] in
            self?.state = .finished
        }
    }

    // MARK: - State hop helpers (to make the @MainActor cross clean)

    private var isCancelledNow: Bool { isCancelled }

    nonisolated private func appendStep(_ step: Step) async {
        await MainActor.run { [weak self] in
            self?.steps.append(step)
        }
    }

    nonisolated private func shouldStop(at stepIndex: Int) async -> Bool {
        await MainActor.run { [weak self] in
            guard let self else { return true }
            return stepIndex >= self.maxSteps
        }
    }

    // MARK: - idb primitives

    struct UIElement {
        let label: String?
        let type: String
        let centerX: Double
        let centerY: Double
        let width: Double
        let height: Double
        var fingerprint: String {
            "\(type)|\(label ?? "")|\(Int(centerX))x\(Int(centerY))"
        }
    }

    nonisolated private static func describeUI(idb: String, udid: String) async -> [UIElement]? {
        let out = runIDB(idb: idb, args: ["--udid", udid, "ui", "describe-all", "--json"])
        guard !out.isEmpty else { return nil }
        guard let data = out.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        var elements: [UIElement] = []
        for item in arr {
            guard let frame = item["frame"] as? [String: Any],
                  let x = frame["x"] as? Double,
                  let y = frame["y"] as? Double,
                  let w = frame["width"] as? Double,
                  let h = frame["height"] as? Double else { continue }
            let type = (item["type"] as? String) ?? "unknown"
            // Focus on tappable-ish elements. Static text / images aren't
            // interesting to exercise on their own.
            let tappable: Set<String> = ["Button", "Cell", "Link", "Switch", "Tab",
                                          "TextField", "SearchField", "SegmentedControl"]
            guard tappable.contains(type) else { continue }
            // Zero-size and off-screen elements are noise.
            guard w > 4, h > 4, x >= 0, y >= 0 else { continue }
            let label = (item["AXLabel"] as? String) ?? (item["title"] as? String)
            elements.append(UIElement(
                label: label,
                type: type,
                centerX: x + w / 2,
                centerY: y + h / 2,
                width: w,
                height: h
            ))
        }
        return elements
    }

    nonisolated private static func nextCandidate(
        from elements: [UIElement],
        skipping: Set<String>
    ) -> UIElement? {
        elements.first { !skipping.contains($0.fingerprint) }
    }

    /// Returns the idb exit status so the loop can record a failure step
    /// instead of silently claiming success on an invalid coordinate or
    /// dropped device connection.
    nonisolated private static func tap(idb: String, udid: String, x: Double, y: Double) async -> Int32 {
        runIDBStatus(idb: idb, args: ["--udid", udid, "ui", "tap",
                                       String(Int(x)), String(Int(y))])
    }

    nonisolated private static func swipeBack(idb: String, udid: String) async -> Int32 {
        runIDBStatus(idb: idb, args: ["--udid", udid, "ui", "swipe",
                                       "0", "400", "300", "400", "--duration", "0.2"])
    }

    nonisolated private static func captureFrame(udid: String, dir: URL, index: Int) async -> URL? {
        let url = dir.appendingPathComponent(String(format: "step-%03d.png", index))
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        proc.arguments = ["simctl", "io", udid, "screenshot", url.path]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        do {
            try proc.run()
            proc.waitUntilExit()
        } catch { return nil }
        return proc.terminationStatus == 0 ? url : nil
    }

    // MARK: - Helpers

    nonisolated private static func findIDB() -> String? {
        let which = Process()
        which.executableURL = URL(fileURLWithPath: "/bin/bash")
        which.arguments = ["-lc", "command -v idb || true"]
        let pipe = Pipe()
        which.standardOutput = pipe
        which.standardError = Pipe()
        try? which.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        which.waitUntilExit()
        let found = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !found.isEmpty, FileManager.default.isExecutableFile(atPath: found) { return found }
        let candidates = [
            "/opt/homebrew/bin/idb",
            "/usr/local/bin/idb",
            "\(NSHomeDirectory())/.local/bin/idb"
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    nonisolated private static func findBootedUDID() -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        proc.arguments = ["simctl", "list", "devices", "booted", "-j"]
        let out = Pipe()
        proc.standardOutput = out
        proc.standardError = Pipe()
        do { try proc.run() } catch { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: Any] else { return nil }
        for (_, list) in devices {
            guard let arr = list as? [[String: Any]] else { continue }
            for entry in arr where (entry["state"] as? String) == "Booted" {
                if let udid = entry["udid"] as? String { return udid }
            }
        }
        return nil
    }

    nonisolated private static func runIDB(idb: String, args: [String]) -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: idb)
        proc.arguments = args
        let out = Pipe()
        proc.standardOutput = out
        proc.standardError = Pipe()
        do { try proc.run() } catch { return "" }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Like runIDB but returns the exit status instead of stdout — used by
    /// fire-and-forget commands (tap, swipe) so the loop can record failures.
    nonisolated private static func runIDBStatus(idb: String, args: [String]) -> Int32 {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: idb)
        proc.arguments = args
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        do { try proc.run() } catch { return -1 }
        proc.waitUntilExit()
        return proc.terminationStatus
    }

    nonisolated private static func timestampString() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df.string(from: Date())
    }
}

private extension AutoExplorer.State {
    var isFinished: Bool {
        switch self {
        case .finished, .failed, .unavailable: return true
        default: return false
        }
    }
}
