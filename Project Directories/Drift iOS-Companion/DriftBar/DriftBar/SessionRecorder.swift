import Foundation
import AppKit
import Combine

/// Turns a Drift session into a TV channel: waits for a booted simulator,
/// records video of it via `simctl io recordVideo`, and polls `simctl io screenshot`
/// on a short interval so the UI can show a near-live mirror of the device.
///
/// Timeline:
///   idle → waitingForSimulator (claude boots the sim) → recording → stopped
///
/// Outputs are persisted per session under `drift-reports/sessions/{stamp}/`:
///   - `recording.mp4`  (full video for later playback)
///   - `session.log`    (written by DriftSession in parallel)
///   - `current.png`    (most recent mirror frame, optional)
@MainActor
final class SessionRecorder: ObservableObject {

    enum State: Equatable {
        case idle
        case waitingForSimulator
        case recording(udid: String)
        case stopped
        case failed(String)
    }

    @Published var state: State = .idle
    @Published var sessionDir: URL?
    @Published var recordingURL: URL?
    @Published var currentFrame: NSImage?
    @Published var frameCount: Int = 0
    @Published var recordingSeconds: TimeInterval = 0
    @Published var bootedDeviceName: String?

    private var pollTimer: Timer?
    private var recordProcess: Process?
    private var recordStartedAt: Date?
    private var screenshotInFlight: Bool = false
    private var stopped: Bool = false

    private let mirrorInterval: TimeInterval = 0.8
    private let bootPollInterval: TimeInterval = 1.0

    var isActive: Bool {
        switch state {
        case .waitingForSimulator, .recording: return true
        default: return false
        }
    }

    // MARK: - Lifecycle

    /// Begin watching for a booted simulator. Once one is up, recording starts
    /// automatically. Call `stop()` when the Claude session ends to finalize
    /// the MP4.
    func start(projectDirectory: URL) {
        guard case .idle = state else { return }
        stopped = false
        frameCount = 0
        recordingSeconds = 0
        currentFrame = nil
        recordingURL = nil
        bootedDeviceName = nil

        let stamp = Self.timestampString()
        let dir = projectDirectory
            .appendingPathComponent("drift-reports", isDirectory: true)
            .appendingPathComponent("sessions", isDirectory: true)
            .appendingPathComponent(stamp, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.sessionDir = dir
        self.state = .waitingForSimulator

        // Boot poll fires on the main actor but the actual simctl probe runs
        // on a detached task — small but non-zero latency.
        pollTimer = Timer.scheduledTimer(withTimeInterval: bootPollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func stop() {
        guard !stopped else { return }
        stopped = true
        pollTimer?.invalidate()
        pollTimer = nil

        // SIGINT lets `simctl io recordVideo` finalize the MP4 cleanly — a
        // hard terminate leaves a half-written, unplayable file.
        if let proc = recordProcess, proc.isRunning {
            kill(proc.processIdentifier, SIGINT)
        }
        recordProcess = nil
        state = .stopped
    }

    // MARK: - Tick loop

    private func tick() {
        switch state {
        case .waitingForSimulator:
            probeForBootedSimulator()
        case .recording:
            if let s = recordStartedAt {
                recordingSeconds = Date().timeIntervalSince(s)
            }
            pollScreenshotIfNeeded()
        default:
            break
        }
    }

    private func probeForBootedSimulator() {
        Task.detached { [weak self] in
            let probe = Self.findBootedSimulator()
            await MainActor.run { [weak self] in
                guard let self else { return }
                guard case .waitingForSimulator = self.state else { return }
                guard let probe else { return }
                self.bootedDeviceName = probe.name
                self.beginRecording(udid: probe.udid)
                // Prime the mirror with the first screenshot immediately,
                // rather than waiting the full poll interval.
                self.pollScreenshotIfNeeded()
                // Switch the timer to the faster mirror cadence.
                self.pollTimer?.invalidate()
                self.pollTimer = Timer.scheduledTimer(withTimeInterval: self.mirrorInterval, repeats: true) { [weak self] _ in
                    Task { @MainActor in self?.tick() }
                }
            }
        }
    }

    // MARK: - Recording

    private func beginRecording(udid: String) {
        guard let dir = sessionDir else { return }
        let mp4 = dir.appendingPathComponent("recording.mp4")
        recordingURL = mp4

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        proc.arguments = ["simctl", "io", udid, "recordVideo",
                          "--codec=h264",
                          "--force",
                          mp4.path]
        // simctl streams status to stderr; silence both — the MP4 file is the signal.
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()

        proc.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                // Only flip to .stopped if a normal stop() already fired. An
                // unexpected exit (sim quit mid-session) should surface as
                // failed so the UI doesn't silently lie about recording.
                if !self.stopped {
                    self.state = .failed("recordVideo exited unexpectedly")
                    self.recordProcess = nil
                }
            }
        }

        do {
            try proc.run()
            recordProcess = proc
            recordStartedAt = Date()
            state = .recording(udid: udid)
        } catch {
            state = .failed("Couldn't start recordVideo: \(error.localizedDescription)")
        }
    }

    // MARK: - Screenshot polling

    private func pollScreenshotIfNeeded() {
        guard case .recording(let udid) = state else { return }
        guard !screenshotInFlight else { return }
        screenshotInFlight = true

        Task.detached { [weak self] in
            let image = Self.snapshotImage(udid: udid)
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.screenshotInFlight = false
                if let image {
                    self.currentFrame = image
                    self.frameCount &+= 1
                    if let dir = self.sessionDir {
                        // Best-effort: persist the latest frame for quick preview
                        // by consumers who don't want to decode the video.
                        if let tiff = image.tiffRepresentation,
                           let rep = NSBitmapImageRep(data: tiff),
                           let png = rep.representation(using: .png, properties: [:]) {
                            try? png.write(to: dir.appendingPathComponent("current.png"))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    nonisolated private static func timestampString() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df.string(from: Date())
    }

    struct BootedSimulator { let udid: String; let name: String }

    nonisolated private static func findBootedSimulator() -> BootedSimulator? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        proc.arguments = ["simctl", "list", "devices", "booted", "-j"]
        let out = Pipe()
        proc.standardOutput = out
        proc.standardError = Pipe()
        do {
            try proc.run()
        } catch { return nil }
        // Drain the pipe before waiting to avoid a buffer-full deadlock —
        // `simctl list -j` can emit a sizeable blob if many runtimes are
        // installed.
        let data = out.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: Any] else { return nil }
        for (_, list) in devices {
            guard let arr = list as? [[String: Any]] else { continue }
            for entry in arr {
                let isBooted = (entry["state"] as? String) == "Booted"
                guard isBooted else { continue }
                guard let udid = entry["udid"] as? String else { continue }
                let name = (entry["name"] as? String) ?? "iOS Simulator"
                return BootedSimulator(udid: udid, name: name)
            }
        }
        return nil
    }

    /// Captures a single frame from the booted simulator. Pipes stdout so we
    /// don't litter the disk with per-frame PNGs — only the final `current.png`
    /// is kept on disk, everything else lives in memory.
    nonisolated private static func snapshotImage(udid: String) -> NSImage? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        proc.arguments = ["simctl", "io", udid, "screenshot", "-"]
        let out = Pipe()
        proc.standardOutput = out
        proc.standardError = Pipe()
        do {
            try proc.run()
        } catch { return nil }

        // Drain before waitUntilExit so large PNGs don't deadlock the pipe
        // buffer (macOS default is 64KB — most sim frames are bigger).
        let data = out.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0, !data.isEmpty else { return nil }
        return NSImage(data: data)
    }
}
