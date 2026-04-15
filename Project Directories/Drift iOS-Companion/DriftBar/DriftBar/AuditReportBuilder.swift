import Foundation

/// Generates a standalone HTML report comparing the audit state before and after a fix run.
/// Output: drift-reports/audit-fix-{timestamp}/index.html  (+ assets)
enum AuditReportBuilder {

    struct Input {
        let before: AuditEngine.Report
        let after: AuditEngine.Report
        let changedFiles: [String]
        let gitDiff: String              // unified diff of changed files (git diff HEAD)
        let projectDirectory: URL
        let fixerLog: String
        let startedAt: Date
        let finishedAt: Date
        let beforeShot: URL?
        let afterShot: URL?
    }

    static func build(_ input: Input) throws -> URL {
        let ts = Self.timestamp(input.finishedAt)
        let outDir = input.projectDirectory
            .appendingPathComponent("drift-reports", isDirectory: true)
            .appendingPathComponent("audit-fix-\(ts)", isDirectory: true)
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        // Copy any provided screenshots into the report dir so the HTML is self-contained.
        var localBefore: String?
        var localAfter: String?
        if let b = input.beforeShot {
            let dest = outDir.appendingPathComponent("before.png")
            try? FileManager.default.copyItem(at: b, to: dest)
            localBefore = "before.png"
        }
        if let a = input.afterShot {
            let dest = outDir.appendingPathComponent("after.png")
            try? FileManager.default.copyItem(at: a, to: dest)
            localAfter = "after.png"
        }

        let html = Self.renderHTML(input, beforeName: localBefore, afterName: localAfter)
        let indexURL = outDir.appendingPathComponent("index.html")
        try html.write(to: indexURL, atomically: true, encoding: .utf8)

        let css = Self.css()
        try css.write(to: outDir.appendingPathComponent("styles.css"), atomically: true, encoding: .utf8)

        return indexURL
    }

    // MARK: - HTML rendering

    private static func renderHTML(_ i: Input, beforeName: String? = nil, afterName: String? = nil) -> String {
        let beforeCount = i.before.count
        let afterCount  = i.after.count
        let fixed       = max(0, beforeCount - afterCount)
        let elapsed     = i.finishedAt.timeIntervalSince(i.startedAt)
        let dateStr     = DateFormatter.report.string(from: i.finishedAt)

        let beforeByFile = i.before.byFile
        let afterByFile  = i.after.byFile
        let diffsByFile  = parseUnifiedDiff(i.gitDiff)

        // Determine file set: anything in changed OR in before-list
        var files = Set(i.changedFiles.map { URL(fileURLWithPath: $0).lastPathComponent })
        files.formUnion(beforeByFile.keys)
        let sortedFiles = files.sorted()

        let fileSections = sortedFiles.map { file -> String in
            let beforeItems = beforeByFile[file] ?? []
            let afterItems  = afterByFile[file]  ?? []
            let resolved    = max(0, beforeItems.count - afterItems.count)
            let diffHTML    = diffsByFile[file].map(renderDiff) ?? "<div class=\"no-diff\">No code changes in this file.</div>"
            let violationsHTML = renderViolationDelta(before: beforeItems, after: afterItems)
            let statusClass: String = {
                if beforeItems.isEmpty && afterItems.isEmpty { return "clean" }
                if afterItems.isEmpty { return "resolved" }
                if afterItems.count < beforeItems.count { return "improved" }
                return "unchanged"
            }()
            return """
            <details class="file \(statusClass)" open>
              <summary>
                <span class="file-name">\(escape(file))</span>
                <span class="file-stats">
                  <span class="stat before">\(beforeItems.count)</span>
                  <span class="arrow">→</span>
                  <span class="stat after">\(afterItems.count)</span>
                  <span class="delta resolved">\(resolved > 0 ? "−\(resolved)" : "·")</span>
                </span>
              </summary>
              <div class="file-body">
                <div class="col diff-col">
                  <h4>Code changes</h4>
                  \(diffHTML)
                </div>
                <div class="col violations-col">
                  <h4>Violations</h4>
                  \(violationsHTML)
                </div>
              </div>
            </details>
            """
        }.joined(separator: "\n")

        let kindTable = renderKindTable(before: i.before, after: i.after)

        let fixerLogEscaped = escape(String(i.fixerLog.suffix(8000)))

        return """
        <!doctype html>
        <html lang="en"><head>
        <meta charset="utf-8">
        <title>Drift audit fix · \(dateStr)</title>
        <link rel="stylesheet" href="styles.css">
        </head><body>
        <div class="shell">
          <header class="hero">
            <div class="brand">
              <div class="logo"></div>
              <div>
                <div class="title">Drift · audit fix report</div>
                <div class="subtitle">\(dateStr) · \(i.projectDirectory.lastPathComponent)</div>
              </div>
            </div>
            <div class="stats">
              \(stat("Before", "\(beforeCount)", "before"))
              \(stat("After",  "\(afterCount)",  afterCount == 0 ? "good" : (afterCount < beforeCount ? "warn" : "bad")))
              \(stat("Fixed",  "\(fixed)",       fixed > 0 ? "good" : "neutral"))
              \(stat("Files changed", "\(i.changedFiles.count)", "neutral"))
              \(stat("Elapsed", String(format: "%.1fs", elapsed), "neutral"))
            </div>
          </header>

          \(renderCaptureSection(beforeName: beforeName, afterName: afterName))

          <section class="summary">
            <h2>Summary by rule</h2>
            \(kindTable)
          </section>

          <section class="files">
            <h2>Per-file results</h2>
            \(sortedFiles.isEmpty ? "<p class=\"muted\">No files were affected.</p>" : fileSections)
          </section>

          <section class="log">
            <details>
              <summary>Claude fixer log (last 8k chars)</summary>
              <pre>\(fixerLogEscaped)</pre>
            </details>
          </section>

          <footer>
            <span>Generated by Drift</span>
            <span class="dot">·</span>
            <span>drift.theme.json v1</span>
          </footer>
        </div>
        </body></html>
        """
    }

    private static func stat(_ label: String, _ value: String, _ tone: String) -> String {
        """
        <div class="stat-card tone-\(tone)">
          <div class="stat-value">\(escape(value))</div>
          <div class="stat-label">\(escape(label))</div>
        </div>
        """
    }

    private static func renderCaptureSection(beforeName: String?, afterName: String?) -> String {
        // Three modes: both (A/B slider), one (single shot), neither (skip).
        if beforeName == nil && afterName == nil { return "" }
        if let b = beforeName, let a = afterName {
            return """
            <section class="capture">
              <h2>App preview — before / after</h2>
              <p class="muted">Drag the handle to compare. Screenshots captured from the simulator before and after the fix run.</p>
              <div class="slider" id="abSlider">
                <img class="slider-img after"  src="\(a)" alt="After">
                <div class="slider-clip" id="abClip">
                  <img class="slider-img before" src="\(b)" alt="Before">
                </div>
                <div class="slider-handle" id="abHandle">
                  <div class="slider-line"></div>
                  <div class="slider-knob">⇄</div>
                </div>
                <div class="slider-label left">Before</div>
                <div class="slider-label right">After</div>
              </div>
              <script>
                (function(){
                  const slider = document.getElementById('abSlider');
                  const clip   = document.getElementById('abClip');
                  const handle = document.getElementById('abHandle');
                  let dragging = false;
                  function setPct(p){
                    p = Math.max(0, Math.min(100, p));
                    clip.style.width = p + '%';
                    handle.style.left = p + '%';
                  }
                  setPct(50);
                  function onMove(e){
                    if(!dragging) return;
                    const rect = slider.getBoundingClientRect();
                    const x = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left;
                    setPct((x / rect.width) * 100);
                  }
                  handle.addEventListener('mousedown', ()=>{ dragging = true; });
                  slider.addEventListener('mousedown', (e)=>{ dragging = true; onMove(e); });
                  window.addEventListener('mouseup', ()=>{ dragging = false; });
                  window.addEventListener('mousemove', onMove);
                  slider.addEventListener('touchstart', (e)=>{ dragging = true; onMove(e); });
                  window.addEventListener('touchend',   ()=>{ dragging = false; });
                  window.addEventListener('touchmove', onMove);
                })();
              </script>
            </section>
            """
        }
        let single = beforeName ?? afterName!
        let label = beforeName != nil ? "Before" : "After"
        return """
        <section class="capture">
          <h2>App preview — \(label.lowercased())</h2>
          <p class="muted">Only the \(label.lowercased()) screenshot was captured. Configure <code>drift.capture.json</code> for both.</p>
          <div class="single-shot"><img src="\(single)" alt="\(label)"></div>
        </section>
        """
    }

    private static func renderKindTable(before: AuditEngine.Report, after: AuditEngine.Report) -> String {
        let rows = Violation.Kind.allKinds.map { kind -> String in
            let b = before.byKind[kind]?.count ?? 0
            let a = after.byKind[kind]?.count  ?? 0
            let delta = b - a
            let cls = delta > 0 ? "good" : (a > b ? "bad" : "neutral")
            let arrow = delta > 0 ? "↓\(delta)" : (a > b ? "↑\(a - b)" : "·")
            return """
            <tr>
              <td>\(kind.label)</td>
              <td class="num">\(b)</td>
              <td class="num">\(a)</td>
              <td class="num tone-\(cls)">\(arrow)</td>
            </tr>
            """
        }.joined()
        return """
        <table class="kinds">
          <thead><tr><th>Rule</th><th>Before</th><th>After</th><th>Δ</th></tr></thead>
          <tbody>\(rows)</tbody>
        </table>
        """
    }

    private static func renderViolationDelta(before: [Violation], after: [Violation]) -> String {
        // Match on (kind, line, snippet) loosely — good enough for a visual list.
        func key(_ v: Violation) -> String { "\(v.kind.rawValue)|\(v.line)|\(v.snippet.trimmingCharacters(in: .whitespaces))" }
        let afterKeys = Set(after.map(key))
        let beforeList = before.sorted { $0.line < $1.line }
        let rows = beforeList.map { v -> String in
            let resolved = !afterKeys.contains(key(v))
            let cls = resolved ? "row-resolved" : "row-remaining"
            let icon = resolved ? "✓" : "×"
            return """
            <li class="\(cls)">
              <span class="v-icon">\(icon)</span>
              <span class="v-line">L\(v.line)</span>
              <span class="v-kind">\(escape(v.kind.label))</span>
              <code class="v-snip">\(escape(v.snippet.trimmingCharacters(in: .whitespaces)))</code>
            </li>
            """
        }.joined()
        if beforeList.isEmpty { return "<p class=\"muted\">No violations in this file before the run.</p>" }
        return "<ul class=\"vlist\">\(rows)</ul>"
    }

    private static func renderDiff(_ diff: String) -> String {
        let lines = diff.components(separatedBy: "\n")
        let body = lines.map { line -> String in
            let cls: String
            if line.hasPrefix("+++") || line.hasPrefix("---") { cls = "meta" }
            else if line.hasPrefix("@@") { cls = "hunk" }
            else if line.hasPrefix("+") { cls = "add" }
            else if line.hasPrefix("-") { cls = "del" }
            else { cls = "ctx" }
            return "<div class=\"d-\(cls)\">\(escape(line.isEmpty ? " " : line))</div>"
        }.joined()
        return "<div class=\"diff\">\(body)</div>"
    }

    // MARK: - Unified diff parsing

    /// Extracts per-file diff blocks keyed by file basename.
    private static func parseUnifiedDiff(_ raw: String) -> [String: String] {
        var result: [String: String] = [:]
        var current: String?
        var buf: [String] = []

        func flush() {
            if let c = current { result[c, default: ""] += buf.joined(separator: "\n") }
            buf.removeAll()
        }

        for line in raw.components(separatedBy: "\n") {
            if line.hasPrefix("diff --git ") {
                flush()
                current = nil
            }
            if line.hasPrefix("+++ b/") {
                let path = String(line.dropFirst("+++ b/".count))
                current = URL(fileURLWithPath: path).lastPathComponent
            } else if let _ = current {
                buf.append(line)
            }
        }
        flush()
        return result
    }

    // MARK: - Helpers

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func timestamp(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: d)
    }

    // MARK: - CSS (Drift-branded)

    private static func css() -> String {
        #"""
        :root {
          --bg:#0b0d10; --bg-elev:#14171c; --bg-hi:#1b1f26;
          --border:#242932; --text:#e7eaf0; --text-dim:#8d97a8; --text-muted:#6b7280;
          --accent:#7aa7ff; --accent-2:#b07aff;
          --pass:#3ecf8e; --warn:#f0b429; --fail:#f06262;
          --mono: ui-monospace, "SF Mono", Menlo, monospace;
        }
        @media (prefers-color-scheme: light) {
          :root { --bg:#fff;--bg-elev:#f7f7f9;--bg-hi:#eef0f4;--border:#e3e5ea;--text:#14171c;--text-dim:#5a6372;--text-muted:#8d97a8;--accent:#3d5996;--accent-2:#8b5cf6;}
        }
        *{box-sizing:border-box} html,body{margin:0;padding:0}
        body{font:15px/1.55 -apple-system,BlinkMacSystemFont,"SF Pro Text",sans-serif;background:var(--bg);color:var(--text);-webkit-font-smoothing:antialiased}
        .shell{max-width:1180px;margin:0 auto;padding:32px 40px 96px}

        /* Hero */
        .hero{display:flex;justify-content:space-between;align-items:center;gap:32px;padding:32px;border:1px solid var(--border);border-radius:16px;background:linear-gradient(135deg,var(--bg-elev),var(--bg-hi));margin-bottom:32px}
        .brand{display:flex;align-items:center;gap:14px}
        .logo{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--accent),var(--accent-2));box-shadow:inset 0 1px 0 rgba(255,255,255,.25)}
        .title{font-weight:600;font-size:18px;letter-spacing:-.01em}
        .subtitle{font-size:13px;color:var(--text-dim);font-family:var(--mono)}

        .stats{display:flex;gap:10px;flex-wrap:wrap}
        .stat-card{padding:10px 14px;border-radius:10px;background:rgba(255,255,255,.03);border:1px solid var(--border);min-width:92px;text-align:right}
        .stat-value{font-size:22px;font-weight:600;letter-spacing:-.02em;font-family:var(--mono)}
        .stat-label{font-size:11px;color:var(--text-dim);text-transform:uppercase;letter-spacing:.05em;margin-top:2px}
        .tone-good .stat-value{color:var(--pass)}
        .tone-warn .stat-value{color:var(--warn)}
        .tone-bad  .stat-value{color:var(--fail)}
        .tone-before .stat-value{color:var(--text-dim)}

        h2{font-size:18px;font-weight:600;margin:40px 0 14px;letter-spacing:-.01em}
        h4{font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:.08em;color:var(--text-dim);margin:0 0 10px}

        /* Kind table */
        table.kinds{width:100%;border-collapse:collapse;background:var(--bg-elev);border:1px solid var(--border);border-radius:10px;overflow:hidden}
        table.kinds th,table.kinds td{padding:10px 14px;text-align:left;border-bottom:1px solid var(--border);font-size:14px}
        table.kinds th{background:var(--bg-hi);font-size:11px;text-transform:uppercase;letter-spacing:.06em;color:var(--text-dim)}
        table.kinds tr:last-child td{border-bottom:none}
        table.kinds td.num{font-family:var(--mono);text-align:right;width:100px}
        .tone-good{color:var(--pass)} .tone-bad{color:var(--fail)} .tone-neutral{color:var(--text-dim)}

        /* Files */
        details.file{border:1px solid var(--border);border-radius:12px;margin-bottom:12px;background:var(--bg-elev);overflow:hidden}
        details.file[open]{background:var(--bg-hi)}
        details.file summary{list-style:none;cursor:pointer;padding:14px 18px;display:flex;justify-content:space-between;align-items:center;gap:16px}
        details.file summary::-webkit-details-marker{display:none}
        .file-name{font-family:var(--mono);font-size:14px;font-weight:500}
        .file-stats{display:flex;align-items:center;gap:8px;font-family:var(--mono);font-size:13px}
        .stat.before{color:var(--text-dim)}
        .stat.after{color:var(--text)}
        .arrow{color:var(--text-muted)}
        .delta.resolved{color:var(--pass);font-weight:600}
        details.file.resolved{border-color:rgba(62,207,142,.35)}
        details.file.improved{border-color:rgba(240,180,41,.35)}

        .file-body{display:grid;grid-template-columns:1.1fr .9fr;gap:20px;padding:0 18px 18px;border-top:1px solid var(--border)}
        .file-body > .col{min-width:0}

        /* Diff */
        .diff{font-family:var(--mono);font-size:12.5px;line-height:1.55;background:var(--bg);border:1px solid var(--border);border-radius:8px;overflow:auto;max-height:560px}
        .diff > div{padding:1px 12px;white-space:pre}
        .d-ctx{color:var(--text)}
        .d-add{background:rgba(62,207,142,.10);color:var(--pass)}
        .d-del{background:rgba(240,98,98,.10);color:var(--fail)}
        .d-hunk{background:rgba(122,167,255,.08);color:var(--accent);border-top:1px solid var(--border);border-bottom:1px solid var(--border)}
        .d-meta{color:var(--text-muted)}
        .no-diff{padding:16px;color:var(--text-dim);font-style:italic;border:1px dashed var(--border);border-radius:8px;text-align:center}

        /* Violation list */
        .vlist{list-style:none;padding:0;margin:0;display:flex;flex-direction:column;gap:6px}
        .vlist li{display:flex;align-items:flex-start;gap:8px;padding:8px 10px;border-radius:6px;background:var(--bg);border:1px solid var(--border)}
        .row-resolved{opacity:.7}
        .row-resolved .v-icon{color:var(--pass)}
        .row-remaining .v-icon{color:var(--fail)}
        .v-icon{font-family:var(--mono);font-weight:700;min-width:14px}
        .v-line{font-family:var(--mono);color:var(--text-dim);font-size:12px;min-width:36px}
        .v-kind{font-size:13px;color:var(--text-dim);min-width:120px}
        .v-snip{font-family:var(--mono);font-size:12px;background:var(--bg-hi);padding:1px 6px;border-radius:4px;flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
        .muted{color:var(--text-dim)}

        /* Log */
        section.log details{background:var(--bg-elev);border:1px solid var(--border);border-radius:10px;padding:10px 14px}
        section.log summary{cursor:pointer;color:var(--text-dim);font-size:13px}
        section.log pre{font-family:var(--mono);font-size:12px;color:var(--text-dim);background:var(--bg);padding:14px;border-radius:8px;overflow:auto;max-height:360px;border:1px solid var(--border);margin-top:10px}

        footer{margin-top:48px;padding-top:20px;border-top:1px solid var(--border);color:var(--text-muted);font-size:12px;font-family:var(--mono);display:flex;gap:8px;justify-content:center}
        footer .dot{opacity:.5}

        @media (max-width: 900px) {
          .file-body{grid-template-columns:1fr}
          .hero{flex-direction:column;align-items:flex-start}
        }

        /* Capture / A-B slider */
        section.capture{margin:40px 0}
        .slider{position:relative;max-width:520px;margin:16px auto;border-radius:24px;overflow:hidden;background:#000;box-shadow:0 30px 80px rgba(0,0,0,.5),0 0 0 1px var(--border);aspect-ratio:9/19.5;user-select:none}
        .slider-img{position:absolute;inset:0;width:100%;height:100%;display:block;object-fit:cover;pointer-events:none}
        .slider-clip{position:absolute;inset:0 auto 0 0;width:50%;height:100%;overflow:hidden}
        .slider-clip img{position:absolute;inset:0;width:520px;max-width:none;height:100%;object-fit:cover}
        .slider-handle{position:absolute;top:0;bottom:0;left:50%;width:2px;background:#fff;transform:translateX(-50%);cursor:ew-resize;box-shadow:0 0 0 1px rgba(0,0,0,.25)}
        .slider-line{position:absolute;inset:0;background:#fff}
        .slider-knob{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:40px;height:40px;border-radius:50%;background:#fff;color:#000;display:flex;align-items:center;justify-content:center;font-size:18px;font-weight:700;box-shadow:0 4px 20px rgba(0,0,0,.4);cursor:ew-resize}
        .slider-label{position:absolute;top:12px;font-family:var(--mono);font-size:11px;font-weight:600;letter-spacing:.08em;text-transform:uppercase;color:#fff;background:rgba(0,0,0,.45);padding:4px 10px;border-radius:12px;backdrop-filter:blur(8px);-webkit-backdrop-filter:blur(8px)}
        .slider-label.left{left:12px}
        .slider-label.right{right:12px}
        .single-shot{text-align:center;margin:16px 0}
        .single-shot img{max-width:400px;border-radius:24px;box-shadow:0 20px 60px rgba(0,0,0,.5),0 0 0 1px var(--border)}
        """#
    }
}

private extension DateFormatter {
    static let report: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f
    }()
}
