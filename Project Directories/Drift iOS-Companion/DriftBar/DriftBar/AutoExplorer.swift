import Foundation
import AppKit
import CryptoKit

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

    // MARK: - Flows (scripted user journeys)

    /// Minimal schema for `drift.flows.json` at the project root. If the file
    /// exists when the tester starts, each flow runs in order, step-by-step,
    /// BEFORE any free exploration — giving deterministic coverage of the
    /// paths the team actually cares about.
    ///
    /// ```json
    /// [
    ///   {"name": "Sign in", "steps": [
    ///     {"tap": "Sign In"},
    ///     {"type": {"target": "Email", "text": "me@example.com"}},
    ///     {"tap": "Continue"}
    ///   ]}
    /// ]
    /// ```
    struct Flow {
        let name: String
        let steps: [FlowStep]
    }

    enum FlowStep {
        case tap(label: String)
        case typeText(target: String, text: String)
        case wait(ms: Int)
        case swipeBack
    }

    struct Step: Identifiable, Equatable {
        let id = UUID()
        let index: Int
        let at: Date
        let action: String           // "tap @ (120, 340)" or "describe-ui"
        let targetLabel: String?     // accessibility label of the tapped element
        let beforeScreenshot: URL?   // pre-action frame
        let afterScreenshot: URL?    // post-action frame
        let verdict: Verdict
        let bugs: [String]           // vision-check findings, one string per issue

        /// Display alias — some UI callers just want "the relevant frame."
        var screenshotPath: URL? { afterScreenshot ?? beforeScreenshot }

        enum Verdict: String, Codable, Equatable {
            case responsive    // the screen changed after the tap
            case unresponsive  // pre/post pixels identical → dead button
            case error         // idb tap itself failed
            case navigation    // used for non-tap steps (swipe-back etc.)
            case unknown       // verification couldn't run (missing frames)
        }
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var steps: [Step] = []
    @Published private(set) var udid: String?
    @Published private(set) var explorationDir: URL?
    @Published private(set) var reportURL: URL?

    private var isCancelled: Bool = false
    private var maxSteps: Int = 20
    private var tapDelayMs: UInt64 = 700
    private var deepCheck: Bool = false
    /// Bumped on every `start()`. The detached task captures this at launch
    /// and aborts quietly at every await hop if a newer run has superseded it —
    /// protects against the user clicking Auto-walk → Stop → Auto-walk fast
    /// enough that the old task is still alive when the new one begins.
    private var runID: UInt64 = 0

    // MARK: - Lifecycle

    /// Kick off exploration. If idb isn't installed, flips to `.unavailable`
    /// and records why. If no simulator is booted, waits for one to come up
    /// (same pattern as SessionRecorder) before actually exploring.
    func start(projectDirectory: URL, maxSteps: Int = 20, deepCheck: Bool = false) {
        guard state == .idle || state.isFinished else { return }
        self.isCancelled = false
        self.maxSteps = maxSteps
        self.deepCheck = deepCheck
        self.steps = []
        self.reportURL = nil
        self.runID &+= 1
        let myRun = self.runID

        let stamp = Self.timestampString()
        let dir = projectDirectory
            .appendingPathComponent("drift-reports", isDirectory: true)
            .appendingPathComponent("exploration", isDirectory: true)
            .appendingPathComponent(stamp, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.explorationDir = dir

        self.state = .waitingForSimulator

        // Load flows now (on main actor with file I/O is cheap) so the
        // detached task can consume them without worrying about isolation.
        let flows = Self.loadFlows(in: projectDirectory)

        Task.detached { [weak self] in
            // 1. Check idb is on PATH.
            guard let idb = Self.findIDB() else {
                await MainActor.run { [weak self] in
                    guard let self, self.runID == myRun else { return }
                    self.state = .unavailable(reason: """
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
                let cancelled = await MainActor.run { [weak self] in
                    guard let self, self.runID == myRun else { return true }
                    return self.isCancelled
                }
                if cancelled { return }
            }
            let stillCurrent1 = await MainActor.run { [weak self] in self?.runID == myRun }
            guard stillCurrent1 else { return }
            guard let bootedUDID = udidOut else {
                await MainActor.run { [weak self] in
                    guard let self, self.runID == myRun else { return }
                    self.state = .failed("No booted simulator appeared after 30s.")
                }
                return
            }
            await MainActor.run { [weak self] in
                guard let self, self.runID == myRun else { return }
                self.udid = bootedUDID
                self.state = .exploring
            }

            // 3. Run scripted flows first (if any), then free exploration.
            if !flows.isEmpty {
                await self?.flowsLoop(idb: idb, udid: bootedUDID, dir: dir,
                                      flows: flows, runID: myRun)
            }
            let keepGoing = await MainActor.run { [weak self] in
                guard let self, self.runID == myRun else { return false }
                return !self.isCancelled
            }
            if keepGoing {
                await self?.explorationLoop(idb: idb, udid: bootedUDID,
                                            dir: dir, runID: myRun)
            }

            // Always write the final report, regardless of which loops ran.
            // But only if we're still the current run — a superseded task
            // shouldn't overwrite the new run's report file.
            let stillCurrent2 = await MainActor.run { [weak self] in self?.runID == myRun }
            guard stillCurrent2 else { return }
            let finalSteps = await MainActor.run { [weak self] in self?.steps ?? [] }
            TesterReport.write(dir: dir, steps: finalSteps)
            await MainActor.run { [weak self] in
                guard let self, self.runID == myRun else { return }
                self.reportURL = dir.appendingPathComponent("report.html")
                // Don't overwrite .failed — those carry a specific reason the
                // UI is displaying. Any other state transitions to .finished.
                if case .failed = self.state { return }
                self.state = .finished
            }
        }
    }

    func stop() {
        isCancelled = true
        if state == .exploring || state == .waitingForSimulator {
            state = .finished
        }
    }

    // MARK: - Loop

    nonisolated private func explorationLoop(idb: String, udid: String, dir: URL, runID: UInt64) async {
        // Continue numbering where flows (if any) left off, so screenshot
        // filenames don't collide and Step.index is monotonic across the run.
        let startIndex = await MainActor.run { [weak self] in self?.steps.count ?? 0 }
        var stepIndex = startIndex
        var alreadyTapped: Set<String> = []
        // "after" of step N is "before" of step N+1 — cache so we save a
        // ~300ms screenshot call per iteration.
        var cachedBefore: URL?

        while true {
            let (cancelled, stale) = await MainActor.run { [weak self] in
                guard let self, self.runID == runID else { return (true, true) }
                return (self.isCancelled, false)
            }
            if stale || cancelled { break }
            // Stop once the *exploration-only* step count hits maxSteps —
            // not stepIndex, which may already include flow steps.
            if (stepIndex - startIndex) >= (await MainActor.run { [weak self] in self?.maxSteps ?? 0 }) {
                break
            }

            // 1. Capture the current state as this step's "before" frame.
            let before: URL?
            if let cached = cachedBefore {
                before = cached
            } else {
                before = await Self.captureFrame(udid: udid, dir: dir,
                                                 index: stepIndex, suffix: "before")
            }

            // 2. Describe the accessibility tree and pick a target.
            guard let elements = await Self.describeUI(idb: idb, udid: udid) else {
                await self.appendStep(Step(
                    index: stepIndex,
                    at: Date(),
                    action: "describe-ui failed",
                    targetLabel: nil,
                    beforeScreenshot: before,
                    afterScreenshot: nil,
                    verdict: .error,
                    bugs: []
                ))
                break
            }

            let candidate = Self.nextCandidate(from: elements, skipping: alreadyTapped)

            // 3. Execute the action (tap or swipe-back) and capture "after".
            let action: String
            let label: String?
            var tapStatus: Int32 = 0
            let isNavigation: Bool

            if let target = candidate {
                alreadyTapped.insert(target.fingerprint)
                tapStatus = await Self.tap(idb: idb, udid: udid, x: target.centerX, y: target.centerY)
                action = "tap @ (\(Int(target.centerX)), \(Int(target.centerY)))"
                label = target.label
                isNavigation = false
            } else {
                // Dead-end — swipe-back from the left edge to unwind.
                _ = await Self.swipeBack(idb: idb, udid: udid)
                action = "swipe-back (no new targets)"
                label = nil
                isNavigation = true
            }

            try? await Task.sleep(nanoseconds: UInt64(self.tapDelayMs) * 1_000_000)
            let after = await Self.captureFrame(udid: udid, dir: dir, index: stepIndex, suffix: "after")

            // 4. Classify the result.
            let verdict: Step.Verdict
            if tapStatus != 0 {
                verdict = .error
            } else if isNavigation {
                verdict = .navigation
            } else if let b = before, let a = after, Self.pixelsIdentical(b, a) {
                verdict = .unresponsive
            } else if before != nil && after != nil {
                verdict = .responsive
            } else {
                verdict = .unknown
            }

            let annotatedAction = (tapStatus != 0)
                ? "tap failed (idb exit \(tapStatus)) @ \(action.dropFirst(5))"
                : action

            // Optional: vision pass over the "after" frame to surface layout bugs.
            // Skipped when the tap errored (the frame didn't really change) or
            // when the user didn't opt in — each call is a ~3–5s Claude roundtrip.
            let bugs: [String]
            let runDeep = await MainActor.run { [weak self] in self?.deepCheck ?? false }
            if runDeep, let frame = after, verdict != .error {
                bugs = await Self.analyzeScreen(at: frame)
            } else {
                bugs = []
            }

            await self.appendStep(Step(
                index: stepIndex,
                at: Date(),
                action: annotatedAction,
                targetLabel: label,
                beforeScreenshot: before,
                afterScreenshot: after,
                verdict: verdict,
                bugs: bugs
            ))

            cachedBefore = after
            stepIndex += 1
        }

        // Report writing + final state are handled by the outer Task.detached
        // in start() so flow-only runs also produce a report.
    }

    // MARK: - Flow runner

    nonisolated private static func loadFlows(in dir: URL) -> [Flow] {
        let url = dir.appendingPathComponent("drift.flows.json")
        guard let data = try? Data(contentsOf: url) else { return [] }
        do {
            let rawFlows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
            return rawFlows.compactMap(Self.parseFlow)
        } catch {
            return []
        }
    }

    nonisolated private static func parseFlow(_ dict: [String: Any]) -> Flow? {
        guard let name = dict["name"] as? String,
              let rawSteps = dict["steps"] as? [[String: Any]] else { return nil }
        let steps = rawSteps.compactMap(Self.parseFlowStep)
        guard !steps.isEmpty else { return nil }
        return Flow(name: name, steps: steps)
    }

    nonisolated private static func parseFlowStep(_ dict: [String: Any]) -> FlowStep? {
        // Support both `{"tap": "Label"}` and `{"type": {"target": "x", "text": "y"}}`.
        if let label = dict["tap"] as? String { return .tap(label: label) }
        if let body = dict["type"] as? [String: Any],
           let target = body["target"] as? String,
           let text = body["text"] as? String {
            return .typeText(target: target, text: text)
        }
        if let ms = dict["wait"] as? Int { return .wait(ms: ms) }
        if dict["swipeBack"] as? Bool == true { return .swipeBack }
        return nil
    }

    nonisolated private func flowsLoop(idb: String, udid: String, dir: URL, flows: [Flow], runID: UInt64) async {
        var stepIndex = await MainActor.run { [weak self] in self?.steps.count ?? 0 }
        var cachedBefore: URL?

        for flow in flows {
            let (cancelled, stale) = await MainActor.run { [weak self] in
                guard let self, self.runID == runID else { return (true, true) }
                return (self.isCancelled, false)
            }
            if stale || cancelled { return }

            // Record a marker step for the flow boundary so the report reads
            // as a narrative ("=== Sign in ===") rather than a flat list.
            await self.appendStep(Step(
                index: stepIndex,
                at: Date(),
                action: "▸ flow: \(flow.name)",
                targetLabel: nil,
                beforeScreenshot: nil,
                afterScreenshot: nil,
                verdict: .navigation,
                bugs: []
            ))
            stepIndex += 1

            for flowStep in flow.steps {
                let (cancelled, stale) = await MainActor.run { [weak self] in
                    guard let self, self.runID == runID else { return (true, true) }
                    return (self.isCancelled, false)
                }
                if stale || cancelled { return }

                let before: URL?
                if let cached = cachedBefore {
                    before = cached
                } else {
                    before = await Self.captureFrame(udid: udid, dir: dir,
                                                     index: stepIndex, suffix: "before")
                }

                let (action, label, exitStatus) = await Self.performFlowStep(
                    flowStep, idb: idb, udid: udid
                )

                try? await Task.sleep(nanoseconds: UInt64(self.tapDelayMs) * 1_000_000)
                let after = await Self.captureFrame(udid: udid, dir: dir,
                                                    index: stepIndex, suffix: "after")

                let verdict: Step.Verdict
                if exitStatus < 0 {
                    verdict = .error
                } else if case .wait = flowStep {
                    verdict = .navigation
                } else if let b = before, let a = after, Self.pixelsIdentical(b, a) {
                    verdict = .unresponsive
                } else if before != nil && after != nil {
                    verdict = .responsive
                } else {
                    verdict = .unknown
                }

                // Deep check the "after" frame the same way exploration does,
                // so turning on the toggle actually affects scripted flows too.
                let bugs: [String]
                let runDeep = await MainActor.run { [weak self] in self?.deepCheck ?? false }
                if runDeep, let frame = after, verdict != .error {
                    bugs = await Self.analyzeScreen(at: frame)
                } else {
                    bugs = []
                }

                await self.appendStep(Step(
                    index: stepIndex,
                    at: Date(),
                    action: action,
                    targetLabel: label,
                    beforeScreenshot: before,
                    afterScreenshot: after,
                    verdict: verdict,
                    bugs: bugs
                ))

                cachedBefore = after
                stepIndex += 1
            }
        }
    }

    /// Executes a single flow step. Returns (action description, target label,
    /// exit status). Status < 0 means the step failed outright (e.g., idb
    /// couldn't find the label); 0 means it ran successfully.
    nonisolated private static func performFlowStep(_ step: FlowStep, idb: String, udid: String)
    async -> (String, String?, Int32) {
        switch step {
        case .tap(let label):
            guard let elements = await describeUI(idb: idb, udid: udid),
                  let target = matchLabel(label, in: elements) else {
                return ("tap \"\(label)\" (not found)", label, -1)
            }
            let status = await tap(idb: idb, udid: udid,
                                   x: target.centerX, y: target.centerY)
            return ("tap \"\(label)\"", label, status)

        case .typeText(let target, let text):
            // Tap the target first to focus the field, then pipe the text.
            guard let elements = await describeUI(idb: idb, udid: udid),
                  let el = matchLabel(target, in: elements) else {
                return ("type into \"\(target)\" (not found)", target, -1)
            }
            _ = await tap(idb: idb, udid: udid, x: el.centerX, y: el.centerY)
            try? await Task.sleep(nanoseconds: 250_000_000)
            let status = runIDBStatus(idb: idb, args: ["ui", "text", text, "--udid", udid])
            return ("type \"\(text)\" into \"\(target)\"", target, status)

        case .wait(let ms):
            try? await Task.sleep(nanoseconds: UInt64(max(0, ms)) * 1_000_000)
            return ("wait \(ms)ms", nil, 0)

        case .swipeBack:
            let status = await swipeBack(idb: idb, udid: udid)
            return ("swipe-back", nil, status)
        }
    }

    /// Fuzzy label match — prefer exact case-insensitive, fall back to
    /// containment. Small enough that a tester yaml using natural labels
    /// ("Sign In", "Continue") usually just works.
    nonisolated private static func matchLabel(_ query: String, in elements: [UIElement]) -> UIElement? {
        let needle = query.lowercased()
        if let exact = elements.first(where: { ($0.label ?? "").lowercased() == needle }) {
            return exact
        }
        return elements.first { ($0.label ?? "").lowercased().contains(needle) }
    }

    // MARK: - State hop helpers (to make the @MainActor cross clean)

    nonisolated private func appendStep(_ step: Step) async {
        await MainActor.run { [weak self] in
            self?.steps.append(step)
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
        // `--udid` is subcommand-local in fb-idb 1.1.7 (positional order:
        // subcommand → flags), not a top-level flag as the repo's main
        // branch suggests. Without `--json` the output isn't stable JSON.
        // Verified against a real idb install.
        let out = runIDB(idb: idb, args: ["ui", "describe-all", "--udid", udid, "--json"])
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
        runIDBStatus(idb: idb, args: ["ui", "tap",
                                       String(Int(x)), String(Int(y)),
                                       "--udid", udid])
    }

    nonisolated private static func swipeBack(idb: String, udid: String) async -> Int32 {
        runIDBStatus(idb: idb, args: ["ui", "swipe",
                                       "0", "400", "300", "400",
                                       "--duration", "0.2",
                                       "--udid", udid])
    }

    nonisolated private static func captureFrame(udid: String, dir: URL, index: Int, suffix: String = "") async -> URL? {
        let name: String = suffix.isEmpty
            ? String(format: "step-%03d.png", index)
            : String(format: "step-%03d-%@.png", index, suffix)
        let url = dir.appendingPathComponent(name)
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

    /// Ship a screenshot to Claude with a tight bug-finding prompt. Expects a
    /// JSON array of short bug descriptions back; anything else is treated as
    /// "no bugs found" so a chatty model can't pollute the report with prose.
    /// The call is opt-in (deepCheck) — each one is ~3–5s, which would turn a
    /// 20-step run into a 1–2 minute thing.
    nonisolated private static func analyzeScreen(at frame: URL) async -> [String] {
        guard let claude = findClaude() else { return [] }
        let prompt = """
        You are auditing an iOS app screenshot for visual/layout bugs a real user would notice.
        Screenshot: \(frame.path)

        Read the screenshot and respond with ONLY a JSON array of short strings, each one
        describing a single visible bug. Focus on: text clipping, misalignment, overlapping
        elements, broken/missing images, unreadable color contrast, cut-off labels, UI elements
        that look incomplete. Ignore design-preference nits — only things that look broken.

        Return [] when nothing is wrong. Respond with ONLY the JSON array, no other text.
        """
        let raw = runClaude(claude: claude, prompt: prompt, timeout: 20)
        return parseBugs(from: raw)
    }

    nonisolated private static func runClaude(claude: String, prompt: String, timeout: TimeInterval) -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: claude)
        proc.arguments = ["-p", prompt,
                          "--model", "claude-opus-4-7",
                          "--dangerously-skip-permissions",
                          "--output-format", "text"]
        var env = ProcessInfo.processInfo.environment
        for k in ["ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_BASE_URL",
                  "CLAUDE_CODE_USE_BEDROCK", "CLAUDE_CODE_USE_VERTEX"] {
            env.removeValue(forKey: k)
        }
        proc.environment = env

        let out = Pipe()
        proc.standardOutput = out
        proc.standardError = Pipe()
        do { try proc.run() } catch { return "" }

        // Hard timeout — a wedged claude call can't be allowed to pause the
        // whole tester. GCD's asyncAfter(deadline:) fires exactly once and
        // doesn't hold a thread between now and then (unlike a sleep-poll).
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak proc] in
            guard let proc, proc.isRunning else { return }
            proc.terminate()
        }

        let data = out.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    nonisolated private static func parseBugs(from raw: String) -> [String] {
        // Claude may bracket the JSON with explanatory text — scan for the
        // first `[` and the last `]` and parse the slice between them.
        guard let start = raw.firstIndex(of: "["),
              let end = raw.lastIndex(of: "]"),
              start < end else { return [] }
        let slice = String(raw[start...end])
        guard let data = slice.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            return []
        }
        return arr
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(10)
            .map { String($0) }
    }

    nonisolated private static func findClaude() -> String? {
        // Cheap duplicate of DriftSession.findClaude — kept local to avoid
        // cross-file actor-isolation tangles.
        let which = Process()
        which.executableURL = URL(fileURLWithPath: "/bin/bash")
        which.arguments = ["-lc", "command -v claude || true"]
        let pipe = Pipe()
        which.standardOutput = pipe
        which.standardError = Pipe()
        try? which.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        which.waitUntilExit()
        let found = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !found.isEmpty, FileManager.default.isExecutableFile(atPath: found) { return found }
        let candidates = ["/opt/homebrew/bin/claude", "/usr/local/bin/claude"]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Byte-wise compare two PNGs. Equal bytes ⇒ equal pixels ⇒ the tap
    /// produced no visible change — the cheapest dead-button detector we can
    /// build without reaching for an LLM. Returns false on any read error so
    /// we don't falsely flag things as responsive.
    nonisolated private static func pixelsIdentical(_ a: URL, _ b: URL) -> Bool {
        guard let da = try? Data(contentsOf: a),
              let db = try? Data(contentsOf: b) else { return false }
        if da.count != db.count { return false }
        return SHA256.hash(data: da) == SHA256.hash(data: db)
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
