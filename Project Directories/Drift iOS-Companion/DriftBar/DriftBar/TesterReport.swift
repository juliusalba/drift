import Foundation

/// Writes the tester run's HTML report to `{dir}/report.html`. The report is
/// self-contained (references PNGs by relative path) so users can open it
/// straight from the Finder or email the whole folder as a bug packet.
enum TesterReport {

    static func write(dir: URL, steps: [AutoExplorer.Step]) {
        let url = dir.appendingPathComponent("report.html")
        let html = render(steps: steps)
        try? html.data(using: .utf8)?.write(to: url)
    }

    // MARK: - Rendering

    private static func render(steps: [AutoExplorer.Step]) -> String {
        let summary = Summary(steps: steps)
        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>Drift Tester Report</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          \(styleBlock)
        </head>
        <body>
          <header>
            <h1>Drift Tester Report</h1>
            <p class="ts">\(isoNow())</p>
            \(summaryCards(summary))
          </header>
          \(bugsSection(steps))
          <section class="steps">
            <h2>Steps</h2>
            \(steps.map(stepCard).joined())
          </section>
        </body>
        </html>
        """
    }

    private static func summaryCards(_ s: Summary) -> String {
        """
        <div class="cards">
          <div class="card"><span class="num">\(s.total)</span><span class="lbl">Steps</span></div>
          <div class="card ok"><span class="num">\(s.responsive)</span><span class="lbl">Responsive</span></div>
          <div class="card bad"><span class="num">\(s.unresponsive)</span><span class="lbl">Dead buttons</span></div>
          <div class="card err"><span class="num">\(s.errors)</span><span class="lbl">Errors</span></div>
          <div class="card warn"><span class="num">\(s.bugCount)</span><span class="lbl">Visual bugs</span></div>
        </div>
        """
    }

    private static func bugsSection(_ steps: [AutoExplorer.Step]) -> String {
        let bugSteps = steps.filter { !$0.bugs.isEmpty || $0.verdict == .unresponsive }
        guard !bugSteps.isEmpty else { return "" }
        let rows = bugSteps.map { step -> String in
            let verdictBadge = renderVerdict(step.verdict)
            let bugList: String = {
                if step.verdict == .unresponsive {
                    return "<li>Tap had no visible effect on screen.</li>"
                }
                return step.bugs.map { "<li>\(escape($0))</li>" }.joined()
            }()
            return """
            <li>
              <div class="bug-head">
                \(verdictBadge)
                <strong>Step \(step.index + 1)</strong>
                <span class="target">\(escape(step.targetLabel ?? step.action))</span>
              </div>
              <ul class="bug-list">\(bugList)</ul>
            </li>
            """
        }.joined()
        return """
        <section class="bugs">
          <h2>Findings</h2>
          <ul>\(rows)</ul>
        </section>
        """
    }

    private static func stepCard(_ step: AutoExplorer.Step) -> String {
        let verdictBadge = renderVerdict(step.verdict)
        let before = imageTag(step.beforeScreenshot, alt: "before")
        let after = imageTag(step.afterScreenshot, alt: "after")
        let bugs: String = step.bugs.isEmpty
            ? ""
            : "<ul class='bug-list inline'>\(step.bugs.map { "<li>\(escape($0))</li>" }.joined())</ul>"
        return """
        <article class="step verdict-\(step.verdict.rawValue)">
          <header>
            <span class="idx">#\(step.index + 1)</span>
            \(verdictBadge)
            <span class="target">\(escape(step.targetLabel ?? "(no label)"))</span>
          </header>
          <div class="action">\(escape(step.action))</div>
          <div class="frames">
            <figure>\(before)<figcaption>before</figcaption></figure>
            <figure>\(after)<figcaption>after</figcaption></figure>
          </div>
          \(bugs)
        </article>
        """
    }

    private static func imageTag(_ url: URL?, alt: String) -> String {
        guard let url else {
            return "<div class='missing'>no frame</div>"
        }
        return "<img src='\(escape(url.lastPathComponent))' alt='\(alt)' loading='lazy'>"
    }

    private static func renderVerdict(_ v: AutoExplorer.Step.Verdict) -> String {
        let (cls, label): (String, String) = {
            switch v {
            case .responsive:   return ("ok",   "RESPONSIVE")
            case .unresponsive: return ("bad",  "DEAD BUTTON")
            case .error:        return ("err",  "ERROR")
            case .navigation:   return ("nav",  "NAV")
            case .unknown:      return ("grey", "UNKNOWN")
            }
        }()
        return "<span class='pill \(cls)'>\(label)</span>"
    }

    // MARK: - Helpers

    /// Must be a func, not a `static let` — a static let is evaluated once
    /// per process lifetime, which would stamp every report with the time of
    /// the first run. Generating on each call is cheap.
    private static func isoNow() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private static func escape(_ s: String) -> String {
        // `'` is escaped because some attributes in this template use single
        // quotes (`<img src='...'>`). If a step label ever contained a stray
        // apostrophe it would break attribute parsing otherwise.
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
         .replacingOccurrences(of: "'", with: "&#39;")
    }

    // MARK: - Summary model

    private struct Summary {
        let total: Int
        let responsive: Int
        let unresponsive: Int
        let errors: Int
        let bugCount: Int

        init(steps: [AutoExplorer.Step]) {
            total = steps.count
            responsive = steps.filter { $0.verdict == .responsive }.count
            unresponsive = steps.filter { $0.verdict == .unresponsive }.count
            errors = steps.filter { $0.verdict == .error }.count
            bugCount = steps.reduce(0) { $0 + $1.bugs.count }
        }
    }

    // MARK: - Styles

    private static let styleBlock: String = """
    <style>
      :root {
        color-scheme: light dark;
        --bg: #0e1116; --panel: #1a1f27; --border: #2a2f3a;
        --text: #e7ecf3; --dim: #9aa4b2; --muted: #6b7280;
        --ok: #22c55e; --bad: #ef4444; --warn: #f59e0b; --err: #dc2626; --grey: #6b7280; --nav: #60a5fa;
      }
      * { box-sizing: border-box; }
      body { margin: 0; padding: 24px; font: 14px/1.5 -apple-system, system-ui, sans-serif;
             background: var(--bg); color: var(--text); }
      header h1 { margin: 0 0 4px 0; font-size: 24px; }
      .ts { color: var(--dim); font-family: ui-monospace, monospace; font-size: 12px; margin: 0 0 16px 0; }
      .cards { display: flex; gap: 12px; margin-bottom: 24px; flex-wrap: wrap; }
      .card { background: var(--panel); border: 1px solid var(--border); border-radius: 10px;
              padding: 14px 18px; min-width: 120px; }
      .card .num { display: block; font-size: 28px; font-weight: 700; }
      .card .lbl { display: block; color: var(--dim); font-size: 11px; text-transform: uppercase; letter-spacing: 0.8px; }
      .card.ok .num { color: var(--ok); }
      .card.bad .num { color: var(--bad); }
      .card.err .num { color: var(--err); }
      .card.warn .num { color: var(--warn); }

      h2 { font-size: 16px; margin: 0 0 12px 0; }
      .bugs { background: var(--panel); border: 1px solid var(--border); border-radius: 10px;
              padding: 16px; margin-bottom: 24px; }
      .bugs ul { list-style: none; padding: 0; margin: 0; }
      .bugs > ul > li { padding: 10px 0; border-bottom: 1px solid var(--border); }
      .bugs > ul > li:last-child { border-bottom: none; }
      .bug-head { display: flex; gap: 10px; align-items: center; margin-bottom: 6px; }
      .bug-head .target { color: var(--dim); font-family: ui-monospace, monospace; font-size: 12px; }
      .bug-list { margin: 0; padding-left: 18px; color: var(--text); }
      .bug-list.inline { margin-top: 8px; font-size: 12px; }

      .steps { display: grid; gap: 16px; }
      .step { background: var(--panel); border: 1px solid var(--border); border-radius: 10px;
              padding: 14px; }
      .step.verdict-unresponsive { border-left: 4px solid var(--bad); }
      .step.verdict-error        { border-left: 4px solid var(--err); }
      .step.verdict-responsive   { border-left: 4px solid var(--ok); }
      .step.verdict-navigation   { border-left: 4px solid var(--nav); }
      .step > header { display: flex; gap: 10px; align-items: center; margin-bottom: 8px; }
      .step .idx { color: var(--muted); font-family: ui-monospace, monospace; font-size: 12px; }
      .step .target { color: var(--dim); }
      .step .action { color: var(--muted); font-family: ui-monospace, monospace; font-size: 12px;
                      margin-bottom: 12px; }
      .frames { display: flex; gap: 12px; flex-wrap: wrap; }
      .frames figure { margin: 0; display: flex; flex-direction: column; gap: 4px; }
      .frames img { max-height: 320px; border-radius: 6px; border: 1px solid var(--border);
                    background: #000; display: block; }
      .frames figcaption { color: var(--muted); font-size: 11px; text-transform: uppercase;
                           letter-spacing: 0.8px; }
      .missing { width: 180px; height: 320px; display: flex; align-items: center; justify-content: center;
                 color: var(--muted); border: 1px dashed var(--border); border-radius: 6px; font-size: 12px; }

      .pill { display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 10px;
              font-weight: 700; letter-spacing: 0.8px; }
      .pill.ok   { background: rgba(34,197,94,0.15);   color: var(--ok); }
      .pill.bad  { background: rgba(239,68,68,0.15);   color: var(--bad); }
      .pill.err  { background: rgba(220,38,38,0.15);   color: var(--err); }
      .pill.warn { background: rgba(245,158,11,0.15);  color: var(--warn); }
      .pill.nav  { background: rgba(96,165,250,0.15);  color: var(--nav); }
      .pill.grey { background: rgba(107,114,128,0.18); color: var(--grey); }
    </style>
    """
}
