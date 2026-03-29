# Drift — Development Plan v3.1

**Version:** 3.1
**Date:** March 29, 2026
**What it is:** An autonomous design-compliance QA agent that builds iOS apps, captures every screen, cross-references designs, fixes code, and loops until pixel-perfect.
**How it ships:** Claude Code plugin (.plugin file) with skills, scripts, MCP integrations, and a generated HTML dashboard for visual QA review.

---

## Why a Plugin (Not a Standalone System)

v1 and v2 of this plan described building a separate FastAPI backend with custom agents, PostgreSQL, Celery workers, and a Gemini API integration. That's months of infrastructure work before any design-checking actually happens.

But look at what's already running right now in your Claude Code environment:

| What Drift needs | What you already have |
|---|---|
| Vision model to compare screenshots | Claude's native VLM (you're paying for Max) |
| Figma design fetching | Figma MCP — connected right now |
| Reference screen library | Refero MCP — connected right now |
| Build iOS projects | Bash tool → `xcodebuild` |
| Capture simulator screenshots | Bash tool → `xcrun simctl io` |
| Edit SwiftUI source files | Read/Write/Edit tools |
| Run sub-agents in parallel | Agent tool with sub-agents |
| Looping with state tracking | Skills already do this (qa-loop does 5-pass loops) |
| Design-to-SwiftUI conversion | swift-ui-forge skill — already installed |

Building a standalone system would mean rebuilding all of this from scratch. Building a plugin means Drift is operational in days, not months. And it ships as a `.plugin` file anyone with Claude Code can install.

---

## Architecture: Drift as a Plugin

```
drift.plugin
├── plugin.json                           # Plugin manifest
├── CLAUDE.md                             # Plugin-level instructions
│
├── skills/
│   ├── drift-check/                      # Core: single-pass analysis
│   │   ├── SKILL.md
│   │   ├── scripts/
│   │   │   ├── frame_capture.py          # xcrun simctl screenshots
│   │   │   ├── preview_extractor.py      # SwiftUI Preview rendering
│   │   │   ├── screen_discovery.py       # Static analysis of View graph
│   │   │   ├── visual_diff.py            # SSIM + perceptual hash comparison
│   │   │   └── report_generator.py       # HTML/Markdown report with diffs
│   │   └── references/
│   │       ├── analysis-prompts.md       # VLM prompt templates
│   │       └── severity-matrix.md        # How to classify discrepancies
│   │
│   ├── drift-fix/                        # Auto-fix: translate discrepancies → code edits
│   │   ├── SKILL.md
│   │   ├── scripts/
│   │   │   └── swift_modifier_map.py     # Maps visual properties → SwiftUI modifiers
│   │   └── references/
│   │       ├── fix-patterns.md           # Common fix patterns (color, spacing, font, layout)
│   │       └── safe-edit-rules.md        # What's safe to auto-edit vs. flag for human
│   │
│   ├── drift-loop/                       # Orchestrator: the full autonomous loop
│   │   ├── SKILL.md
│   │   ├── scripts/
│   │   │   └── regression_guard.py       # Cross-iteration comparison
│   │   └── references/
│   │       └── loop-strategy.md          # Exit conditions, diminishing returns logic
│   │
│   └── drift-report/                     # Reporting: before/after, audit trail
│       ├── SKILL.md
│       ├── scripts/
│       │   ├── diff_overlay.py           # Side-by-side screenshot overlay generator
│       │   ├── score_tracker.py          # Track compliance scores across runs
│       │   └── generate_dashboard.py     # Generates the interactive HTML dashboard
│       ├── references/
│       │   └── report-templates.md
│       └── assets/
│           └── dashboard_template.html   # Base HTML/CSS/JS template for the dashboard
│
├── commands/
│   ├── check.md                          # /drift-check — run single analysis pass
│   ├── fix.md                            # /drift-fix — analyze + auto-fix
│   ├── loop.md                           # /drift-loop — full autonomous loop
│   └── report.md                         # /drift-report — generate report from last run
│
└── connectors/                           # MCP dependencies
    └── recommended.json                  # Figma MCP, Refero MCP
```

---

## The Core Loop (drift-loop)

```
┌─────────────────────────────────────────────────────────┐
│                    DRIFT LOOP                            │
│                                                          │
│  ┌─────────┐     ┌──────────┐     ┌──────────────────┐  │
│  │  BUILD   │────►│ CAPTURE  │────►│ FETCH DESIGNS    │  │
│  │          │     │          │     │                  │  │
│  │ xcode-   │     │ simctl   │     │ Figma MCP        │  │
│  │ build    │     │ screen-  │     │ Refero MCP       │  │
│  │          │     │ shots +  │     │ Reference PNGs   │  │
│  │          │     │ Previews │     │                  │  │
│  └─────────┘     └──────────┘     └──────────────────┘  │
│       │                                    │             │
│       │          ┌──────────────┐          │             │
│       │          │   ANALYZE    │◄─────────┘             │
│       │          │              │                        │
│       │          │ Claude VLM   │                        │
│       │          │ (primary)    │                        │
│       │          │ Gemini VLM   │                        │
│       │          │ (fallback)   │                        │
│       │          │              │                        │
│       │          │ Discrepancy  │                        │
│       │          │ report with  │                        │
│       │          │ severity +   │                        │
│       │          │ fix hints    │                        │
│       │          └──────┬───────┘                        │
│       │                 │                                │
│       │                 ▼                                │
│       │          ┌──────────────┐                        │
│       │          │   FIX        │                        │
│       │          │              │                        │
│       │          │ Edit SwiftUI │                        │
│       │          │ source files │                        │
│       │          │ Git commit   │                        │
│       │          └──────┬───────┘                        │
│       │                 │                                │
│       │                 ▼                                │
│       │          ┌──────────────┐                        │
│       │          │  REGRESSION  │                        │
│       │          │  GUARD       │                        │
│       │          │              │                        │
│       │          │ Re-capture   │                        │
│       │          │ all screens  │                        │
│       │          │ Compare N    │                        │
│       │          │ vs N-1       │                        │
│       │          │              │                        │
│       │          │ PASS → Done  │                        │
│       │          │ FAIL → Loop  │                        │
│       │          │ WORSE→Revert │                        │
│       │          └──────────────┘                        │
│       │                 │                                │
│       └─────────────────┘ (rebuild if fixes applied)     │
│                                                          │
│  Stop when:                                              │
│  • All screens pass (score > threshold)                  │
│  • Max iterations reached (default: 5)                   │
│  • Diminishing returns (< 2% gain for 2 iterations)     │
│  • Only cosmetic issues remain                           │
└─────────────────────────────────────────────────────────┘
```

---

## Skill Specifications

### Skill 1: drift-check (Single Analysis Pass)

**Trigger:** "drift check", "check designs", "compare to Figma", "design audit", "how close is this to the designs"

**What it does:**
1. Locates the Xcode project (`.xcodeproj` or `Package.swift`)
2. Builds to simulator via `xcodebuild`
3. Discovers all screens via static analysis of View files (finds `NavigationLink`, `TabView`, `.sheet`, `.fullScreenCover` destinations)
4. Captures screenshots: SwiftUI Previews for individual views + simulator screenshots for full flows
5. Fetches design references:
   - **Figma MCP:** Pull frames from the linked Figma file, export as PNG, extract design tokens (colors, spacing, typography)
   - **Refero MCP:** Search for matching reference screens
   - **Local references:** Load from `designs/` folder if present
6. Matches captured screens to design frames (name-based first, VLM-assisted visual matching as fallback)
7. Analyzes each (build, design) pair using Claude's VLM:
   - Sends both images with a structured comparison prompt
   - Classifies every discrepancy: type, severity, element, expected vs actual, fix hint
8. Generates a compliance report with per-screen scores

**VLM Analysis Prompt (loaded from `references/analysis-prompts.md`):**
```
You are a pixel-perfect iOS design QA specialist. Compare these two images:

IMAGE 1: Screenshot from iOS Simulator (the "build")
IMAGE 2: Design reference from Figma (the "design")

For every visual difference, report as JSON:
{
  "discrepancies": [
    {
      "type": "color|spacing|typography|layout|missing_element|extra_element|alignment|content",
      "severity": "critical|major|minor|cosmetic",
      "element": "description of the UI element",
      "expected": "what the design shows",
      "actual": "what the build shows",
      "fix_hint": "the SwiftUI modifier or property to change",
      "confidence": 0.0-1.0
    }
  ],
  "overall_match_score": 0.0-1.0,
  "summary": "one-line assessment"
}

Severity guide:
- critical: missing/extra element, completely wrong screen, broken layout
- major: color > 10% off, spacing > 4pt off, wrong font family
- minor: spacing 2-4pt off, font weight mismatch, slight alignment
- cosmetic: color < 5% off, subpixel rounding, shadow intensity
```

**Output:** `drift-reports/check-{timestamp}/` folder with:
- `report.md` — full Markdown report
- `screens/` — captured screenshots
- `diffs/` — side-by-side comparison images
- `data.json` — machine-readable discrepancy data

---

### Skill 2: drift-fix (Auto-Fix Engine)

**Trigger:** "drift fix", "fix the design issues", "match the designs", "auto-fix drift"

**What it does:**
1. Reads the latest drift-check report (or runs one if none exists)
2. For each discrepancy above the confidence threshold (default 0.7):
   - Maps the screen name → source `.swift` file via the Capture Agent's screen-to-file mapping
   - Reads the current SwiftUI source
   - Uses Claude to generate a targeted code edit based on the discrepancy + fix hint
   - Applies the edit via the Edit tool
   - Validates the file still parses (quick syntax check)
3. Groups all fixes for the same file into a single edit pass
4. Git commits the changes: `"drift: fix [ScreenName] — [types of fixes]"`

**Fix Pattern Library (loaded from `references/fix-patterns.md`):**

| Discrepancy Type | SwiftUI Fix Pattern |
|---|---|
| Color mismatch | `.foregroundColor(Color(hex: "CORRECT"))` or update theme token |
| Spacing off | `.padding(.horizontal, CORRECT)` or `.spacing(CORRECT)` in Stack |
| Font wrong | `.font(.system(size: N, weight: .W))` or `.font(.custom("Name", size: N))` |
| Corner radius | `.clipShape(RoundedRectangle(cornerRadius: N))` |
| Missing element | Insert the missing SwiftUI view at the correct position in the hierarchy |
| Extra element | Remove or hide with `.opacity(0)` + comment explaining why |
| Alignment | Change Stack alignment: `VStack(alignment: .leading)` |
| Layout order | Reorder children within the VStack/HStack/ZStack |

**Safety Rules (from `references/safe-edit-rules.md`):**
- NEVER edit business logic (data flow, API calls, state management)
- NEVER delete code without explanation
- ONLY edit visual properties: colors, spacing, fonts, layout, sizing, shape
- If a fix would require changing more than 20 lines → flag for human, don't auto-fix
- If confidence < 0.7 → add a `// DRIFT: Suggested fix — [description]` comment instead

---

### Skill 3: drift-loop (Autonomous Orchestrator)

**Trigger:** "drift loop", "run drift", "loop until clean", "fix everything", "make it match the designs"

**What it does:**
1. Runs `drift-check` (initial analysis)
2. If discrepancies found → runs `drift-fix`
3. Rebuilds (`xcodebuild`)
4. If build fails → attempt to fix compile errors (missing imports, type mismatches) → rebuild
5. Re-captures all screens
6. Runs `regression-guard`:
   - Compares ALL screens against previous iteration (not just fixed ones)
   - If a previously-passing screen now fails → regression detected
   - If net score decreased → `git revert` the iteration's commit
7. Runs `drift-check` again on the new build
8. Repeats until exit condition met

**Exit Conditions:**
- All screens score above threshold (default: 0.9) → **PASS**
- Max iterations reached (default: 5) → **STOP** with report
- Two consecutive iterations with < 2% improvement → **DIMINISHING RETURNS**, stop
- Only cosmetic issues remain (no critical/major) → **ACCEPTABLE**, stop
- Regression guard reverted 2 consecutive iterations → **CONFLICT**, needs human

**State Tracking:**
Each iteration writes to `drift-reports/loop-{timestamp}/iteration-{N}/`:
- Screenshots, discrepancy data, fix diffs, compliance scores
- The regression guard reads iteration N-1 to compare

---

### Skill 4: drift-report (Reporting)

**Trigger:** "drift report", "show me the drift results", "what changed", "design compliance report"

**What it does:**
1. Reads the latest loop/check results from `drift-reports/`
2. Generates:
   - **Executive summary:** Overall compliance score, screens passing/failing, iterations completed
   - **Per-screen detail:** Side-by-side screenshots (build vs design) with discrepancy overlays
   - **Fix audit trail:** Every code edit across all iterations, with before/after
   - **Remaining issues:** Discrepancies that couldn't be auto-fixed, with manual fix suggestions
   - **Trend data:** If multiple runs exist, show compliance score over time

**Output formats:**
- Markdown report (quick summary)
- **Interactive HTML dashboard** (primary output — see below)

---

## The Dashboard (Local Web App)

Drift ships with a **Next.js web dashboard** that runs on localhost. The plugin engine writes structured JSON + screenshots to `drift-reports/`, and the dashboard reads from that directory and presents everything in a polished, interactive UI — modeled after the Revyl reference (session viewer with device frame, timeline, tabbed panels, real-time analysis progress, step editing).

Run it with:
```bash
drift serve        # starts on http://localhost:3000
drift serve -p 8080  # custom port
```

The dashboard auto-reloads when new data lands in `drift-reports/` (file watcher), so you can have it open in your browser while `/drift-loop` runs in Claude Code and watch results appear in real time.

### App Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  🏠 Home  /  Runs  /  Run #14 — MyApp                          drift v0.1 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Run #14 — MyApp.xcodeproj                                                  │
│  ⏱ Started: Mar 29, 2:34 PM   ⏳ Duration: 47s   🔄 Iterations: 3/5      │
│  Score: ████████████░░ 87% → 94%                              ✅ Passed    │
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │  Comparison   │  │  Timeline    │  │  Discrepancies│  │  Code Diffs   │  │
│  │  (active)     │  │              │  │              │  │               │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └────────────────┘  │
│                                                                             │
├──────────────────┬──────────────────────────────────────────────────────────┤
│                  │                                                          │
│  SCREENS         │  ┌──────────────────────────────────────────────────┐   │
│                  │  │                  COMPARISON VIEW                  │   │
│  ✅ HomeView     │  │                                                  │   │
│  ✅ Settings     │  │  ┌─────────────┐  ◄══ slider ══►  ┌───────────┐ │   │
│  ✅ Profile      │  │  │             │                   │           │ │   │
│  ⚠️ LoginView   │  │  │   BUILD     │                   │  DESIGN   │ │   │
│  ⚠️ Onboarding  │  │  │ (simulator  │                   │  (Figma)  │ │   │
│  ✅ Transactions │  │  │  screenshot)│                   │           │ │   │
│  ✅ Detail       │  │  │             │                   │           │ │   │
│  ✅ Search       │  │  │  [device    │                   │  [design  │ │   │
│                  │  │  │   frame]    │                   │   frame]  │ │   │
│  Score: 94%      │  │  │             │                   │           │ │   │
│  12 screens      │  │  └─────────────┘                   └───────────┘ │   │
│  10 pass         │  │                                                  │   │
│  2 review        │  │  Discrepancies for LoginView (2):                │   │
│                  │  │  🔴 Color: CTA #3A7BC8, design #377CC8 → FIXED  │   │
│                  │  │  🟡 Spacing: padding 12pt, design 16pt → FIXED  │   │
│                  │  │                                                  │   │
│                  │  │  ┌─ Iteration History ────────────────────────┐  │   │
│                  │  │  │ #1: 71% → 8 issues  │ #2: 87% → 6 fixed  │  │   │
│                  │  │  │ #3: 94% → 2 fixed, 0 regressions         │  │   │
│                  │  │  └───────────────────────────────────────────┘  │   │
│                  │  └──────────────────────────────────────────────────┘   │
│                  │                                                          │
├──────────────────┴──────────────────────────────────────────────────────────┤
│  [📋 Export Report]  [🔄 Re-run Drift]  [📁 Open in Finder]               │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Pages & Views

**1. Home (`/`)**
List of all Drift runs, sorted by date. Each card shows: project name, score trend (sparkline), iteration count, pass/fail status, timestamp. Click to open.

**2. Run Detail (`/runs/:id`)**
The main workspace. Four tabs:

**Tab: Comparison** (default)
- Screen list sidebar (left) — all screens with status icons and scores
- Main panel — side-by-side build vs design screenshots
- **Comparison slider** — drag to blend between build and design (CSS `clip-path`)
- **Discrepancy overlay toggle** — colored bounding boxes on the build screenshot
- **Device frame** — build screenshot wrapped in an iPhone frame (like the reference)
- Per-screen discrepancy list below the comparison
- Iteration history bar showing score progression

**Tab: Timeline**
- Horizontal iteration timeline (like the reference's video timeline)
- Each iteration is a segment showing: score delta, fixes applied, regressions
- Click an iteration to see that snapshot's state
- Animated progress bar for in-progress runs (real-time via file watcher)

**Tab: Discrepancies**
- Full list of all discrepancies across all screens
- Filterable by: severity (critical/major/minor/cosmetic), type (color/spacing/typography/layout), status (open/fixed/wont_fix)
- Each row: screen name, element description, expected vs actual, fix hint, confidence score
- Expand a row to see the visual diff + code diff side by side
- Bulk actions: "Accept all minor", "Flag for review"

**Tab: Code Diffs**
- Git-style diff viewer for every edit Drift made
- Grouped by iteration → file
- Syntax-highlighted Swift diffs (Monaco editor or Prism.js)
- "Revert this change" button per diff (triggers `git revert`)
- Total lines changed, files modified

**3. Analyzing (real-time progress modal)**
When a Drift run is in progress, show a modal (like the reference's "Analyzing Session"):
- Current phase: "Building..." → "Capturing screens..." → "Fetching designs..." → "Analyzing chunk 2 of 4..." → "Applying fixes..."
- Progress bar with step count
- Live screen captures appearing as they're taken
- "You can close this and continue working. This may take up to 60 seconds."

**4. Settings (`/settings`)**
- Figma file ID configuration
- Severity threshold (what counts as "pass")
- Max iterations
- VLM preference (Claude primary + Gemini fallback toggle)
- Device target (which simulator device)

### Tech Stack

| Layer | Choice | Why |
|-------|--------|-----|
| **Framework** | Next.js 14 (App Router) | File-based routing, React Server Components for fast initial loads, API routes for the data layer |
| **Styling** | Tailwind CSS + shadcn/ui | Consistent design system, matches the clean aesthetic from the reference |
| **State** | Zustand | Lightweight, no boilerplate, good for file-watcher driven updates |
| **Image comparison** | Custom React component | CSS `clip-path` slider for build vs design overlay |
| **Code diffs** | `react-diff-viewer-continued` | Syntax-highlighted side-by-side diffs |
| **Charts** | Recharts | Score trend sparklines, compliance gauges |
| **Device frames** | `react-device-frameset` or custom SVG | iPhone frame wrapping simulator screenshots |
| **Real-time updates** | `chokidar` file watcher → Server-Sent Events | Dashboard auto-updates as the plugin writes new data to `drift-reports/` |
| **Data layer** | JSON files in `drift-reports/` | No database needed. The plugin writes JSON, the dashboard reads it. Simple. |

### Data Flow

```
Claude Code Plugin                    Next.js Dashboard
(skills running in CLI)               (localhost:3000)

  drift-check / drift-loop            Browser
  │                                   │
  ├─ writes → drift-reports/          │
  │   ├── runs/                       │
  │   │   └── run-{id}/              │
  │   │       ├── meta.json    ◄──────┤ reads on load
  │   │       ├── iterations/         │
  │   │       │   ├── 1/             │
  │   │       │   │   ├── screens/   │
  │   │       │   │   ├── data.json  │
  │   │       │   │   └── diffs/     │
  │   │       │   ├── 2/             │
  │   │       │   └── 3/             │
  │   │       └── summary.json       │
  │   └── index.json   ◄─────────────┤ reads for home page
  │                                   │
  └─ file changes ──── chokidar ──────┤ SSE push → UI updates
```

The plugin and dashboard are **completely decoupled**. The plugin writes files. The dashboard reads files. They never call each other directly. This means:
- You can run the plugin without the dashboard (CLI-only mode)
- You can open the dashboard after a run to review historical results
- You can have the dashboard open during a run and watch results stream in
- The dashboard works even if Claude Code isn't running

### Dashboard Project Structure

```
drift-dashboard/
├── package.json
├── next.config.js
├── tailwind.config.ts
├── tsconfig.json
│
├── app/
│   ├── layout.tsx                    # Root layout, sidebar nav, theme
│   ├── page.tsx                      # Home: run list
│   ├── runs/
│   │   └── [id]/
│   │       ├── page.tsx              # Run detail (tabbed view)
│   │       └── components/
│   │           ├── ComparisonTab.tsx  # Side-by-side with slider
│   │           ├── TimelineTab.tsx    # Iteration timeline
│   │           ├── DiscrepancyTab.tsx # Filterable issue list
│   │           ├── CodeDiffTab.tsx    # Git-style diff viewer
│   │           └── AnalyzingModal.tsx # Real-time progress
│   ├── settings/
│   │   └── page.tsx                  # Configuration
│   └── api/
│       ├── runs/route.ts             # List/read runs from drift-reports/
│       ├── runs/[id]/route.ts        # Single run detail
│       └── events/route.ts           # SSE endpoint for live updates
│
├── components/
│   ├── ui/                           # shadcn/ui components
│   ├── DeviceFrame.tsx               # iPhone frame wrapper
│   ├── ComparisonSlider.tsx          # Build vs design overlay
│   ├── DiscrepancyOverlay.tsx        # Bounding box renderer
│   ├── ScoreGauge.tsx                # Donut chart
│   ├── IterationTimeline.tsx         # Horizontal progress
│   ├── ScreenSidebar.tsx             # Screen list with status
│   └── SwiftDiffViewer.tsx           # Syntax-highlighted diffs
│
├── lib/
│   ├── data.ts                       # Read drift-reports/ JSON files
│   ├── watcher.ts                    # chokidar file watcher → SSE
│   └── types.ts                      # TypeScript types matching plugin schema
│
└── public/
    └── device-frames/                # iPhone frame SVGs
```

### How It Launches

The plugin includes a `drift serve` command that:

1. Checks if `drift-dashboard/` exists in the plugin directory
2. Runs `npm install` if needed (first time only)
3. Starts `next dev` pointed at the project's `drift-reports/` directory
4. Opens `http://localhost:3000` in the default browser

```bash
# From the drift CLI command:
drift serve                    # http://localhost:3000
drift serve --port 8080        # custom port
drift serve --reports ./path   # custom reports directory
```

Or from Claude Code:
```
/drift-report    →  "Opening Drift dashboard at http://localhost:3000..."
```

---

## How It Relates to Existing Skills

Drift doesn't replace your existing skills — it orchestrates them and fills the gaps:

```
                         ┌──────────────┐
                         │  drift-loop  │ ← NEW: The orchestrator
                         └──────┬───────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                  │
              ▼                 ▼                  ▼
     ┌────────────────┐ ┌──────────────┐ ┌────────────────┐
     │  drift-check   │ │  drift-fix   │ │  drift-report  │
     │  (NEW)         │ │  (NEW)       │ │  (NEW)         │
     │                │ │              │ │                │
     │  Build +       │ │  Code edits  │ │  Reports +     │
     │  Capture +     │ │  based on    │ │  diffs +       │
     │  Compare       │ │  discrepancy │ │  audit trail   │
     └───────┬────────┘ │  analysis    │ └────────────────┘
             │          └──────────────┘
             │
    ┌────────┼─────────────────┐
    │        │                 │
    ▼        ▼                 ▼
┌────────┐ ┌──────────┐ ┌──────────────┐
│ qa-loop│ │swift-ui- │ │ Figma MCP    │
│(EXISTS)│ │forge     │ │ Refero MCP   │
│        │ │(EXISTS)  │ │ (CONNECTED)  │
│ 8-phase│ │ Design → │ │              │
│ static │ │ SwiftUI  │ │ Design specs │
│ audit  │ │ convert  │ │ & references │
└────────┘ └──────────┘ └──────────────┘
```

- **qa-loop** stays as-is for static code analysis (types, imports, a11y, plist, assets). Drift calls qa-loop's phases when relevant.
- **swift-ui-forge** stays as-is for initial design-to-code conversion. Drift uses forge's patterns when generating fix code.
- **Drift** adds what's missing: visual comparison against Figma, autonomous fix loop, regression guarding, compliance scoring.

---

## Plugin Manifest (plugin.json)

```json
{
  "name": "drift",
  "version": "0.1.0",
  "description": "Autonomous design-compliance QA for iOS apps. Builds, captures, compares to Figma designs, auto-fixes SwiftUI code, and loops until pixel-perfect.",
  "skills": [
    "skills/drift-check",
    "skills/drift-fix",
    "skills/drift-loop",
    "skills/drift-report"
  ],
  "commands": [
    "commands/check.md",
    "commands/fix.md",
    "commands/loop.md",
    "commands/report.md"
  ],
  "connectors": {
    "recommended": [
      {
        "name": "Figma MCP",
        "reason": "Required for fetching design frames and design tokens"
      },
      {
        "name": "Refero MCP",
        "reason": "Optional: reference screen library for visual matching"
      }
    ]
  }
}
```

---

## Phase Breakdown

### Phase 0 — Plugin Scaffold + Screen Discovery (Days 1–3)

| Task | Details |
|------|---------|
| Plugin structure | Create the `drift.plugin` directory structure, `plugin.json`, `CLAUDE.md` |
| Screen discovery script | `screen_discovery.py` — parse SwiftUI files, find all View structs, map navigation graph (NavigationLink targets, TabView tabs, sheet destinations) |
| Frame capture script | `frame_capture.py` — wrapper around `xcrun simctl io booted screenshot`, with naming conventions tied to screen discovery |
| Preview extractor | `preview_extractor.py` — find `#Preview` blocks, render via `xcodebuild` preview target |
| Basic build wrapper | Shell commands in the skill to run `xcodebuild` and parse errors |

**Deliverable:** `/drift-check` can build a project, discover screens, and capture screenshots.

---

### Phase 1 — Design Fetching + VLM Analysis (Days 4–8)

| Task | Details |
|------|---------|
| Figma integration | Skill instructions for using Figma MCP tools to fetch frames, export PNGs, extract design tokens |
| Refero integration | Skill instructions for searching Refero for reference screens |
| Screen-to-design matching | Name-based matching first, VLM-assisted fallback for ambiguous cases |
| VLM analysis prompts | Craft and test the comparison prompts in `references/analysis-prompts.md` |
| Severity classification | Implement the severity matrix in `references/severity-matrix.md` |
| Compliance scoring | Per-screen and aggregate score calculation |
| Report generation | `report_generator.py` — Markdown + HTML with side-by-side screenshots |

**Deliverable:** `/drift-check` produces a full discrepancy report comparing build screenshots to Figma designs.

---

### Phase 2 — Auto-Fix Engine (Days 9–14)

| Task | Details |
|------|---------|
| SwiftUI modifier mapping | `swift_modifier_map.py` — maps visual property names to SwiftUI modifier syntax |
| Fix pattern library | `references/fix-patterns.md` — documented patterns for each discrepancy type |
| Safe edit rules | `references/safe-edit-rules.md` — what Drift is and isn't allowed to change |
| Source file mapper | Given screen name → find the .swift file (uses screen_discovery.py output) |
| Code edit generation | Claude-powered: takes discrepancy + current code → outputs targeted Edit tool call |
| Git integration | Auto-commit each fix batch with descriptive messages |
| Syntax validation | Quick check that edited files still parse before committing |

**Deliverable:** `/drift-fix` reads a check report and applies code fixes to SwiftUI source files.

---

### Phase 3 — Loop + Regression Guard (Days 15–20)

| Task | Details |
|------|---------|
| Regression guard | `regression_guard.py` — compares iteration N screenshots against N-1 using SSIM |
| Loop orchestrator | drift-loop SKILL.md — full loop logic with exit conditions |
| State management | Directory-based: each iteration gets its own folder under `drift-reports/` |
| Diminishing returns detector | Track score delta per iteration, stop when plateauing |
| Auto-revert | `git revert` when regression guard detects net negative change |
| Parallel screen processing | Use Agent tool to analyze multiple screens simultaneously |
| Gemini fallback | When Claude VLM result confidence is low, retry with Gemini for second opinion |

**Deliverable:** `/drift-loop` runs the full autonomous cycle end-to-end.

---

### Phase 4 — Web Dashboard (Days 21–32)

| Task | Details |
|------|---------|
| **Next.js scaffold** | Create `drift-dashboard/` with App Router, Tailwind, shadcn/ui, TypeScript |
| **Home page** | Run list with score sparklines, status badges, timestamps |
| **Run detail page** | Tabbed layout: Comparison, Timeline, Discrepancies, Code Diffs |
| **Comparison slider** | Custom React component: CSS `clip-path` slider blending build and design screenshots |
| **Device frame component** | iPhone frame SVG wrapping simulator screenshots (like the Revyl reference) |
| **Discrepancy overlay** | Toggle-able colored bounding boxes rendered on top of screenshots |
| **Screen sidebar** | Clickable screen list with pass/warn/fail status and compliance scores |
| **Iteration timeline** | Horizontal timeline showing score progression per iteration |
| **Code diff viewer** | `react-diff-viewer` with Swift syntax highlighting |
| **Real-time updates** | `chokidar` file watcher → SSE → Zustand store → UI reactively updates during live runs |
| **Analyzing modal** | Real-time progress: "Building..." → "Capturing..." → "Analyzing chunk 2 of 4..." (like the Revyl reference) |
| **Settings page** | Configure Figma file ID, severity threshold, max iterations, device target |
| **`drift serve` command** | Plugin command that starts the Next.js dev server pointed at the project's `drift-reports/` |
| **Data layer** | TypeScript types matching plugin JSON schema, file-reading utilities |

**Deliverable:** `drift serve` opens `http://localhost:3000` with a polished dashboard showing all run history, comparisons, and diffs.

---

### Phase 5 — Integration + Productize (Days 33–38)

| Task | Details |
|------|---------|
| qa-loop integration | When drift-loop encounters non-visual issues (missing imports, type errors), delegate to qa-loop phases |
| swift-ui-forge integration | When drift-fix needs to generate a new View from scratch, delegate to forge patterns |
| Score tracking | `score_tracker.py` — track compliance trends across multiple runs |
| Plugin packaging | Package as `.plugin` file for distribution |
| Documentation | README, usage examples, configuration guide |
| Eval suite | Test cases using the skill-creator's eval framework |

**Deliverable:** Drift ships as an installable `.plugin` file with the bundled dashboard.

---

## Commands (Slash Commands)

### /drift-check
```markdown
---
description: Analyze build vs design — single pass
---
Run a single drift analysis pass on the current project.

1. Find the Xcode project in the workspace
2. Build to simulator
3. Capture all discoverable screens
4. Fetch design references (Figma MCP → Refero MCP → local designs/ folder)
5. Compare each screen against its design reference using VLM
6. Generate a compliance report
```

### /drift-fix
```markdown
---
description: Auto-fix design discrepancies
---
Fix design discrepancies found by drift-check.

1. Read the latest drift-check report
2. For each fixable discrepancy (confidence > 0.7, visual-only):
   - Map screen → source file
   - Generate targeted SwiftUI code edit
   - Apply and validate
3. Git commit all fixes
```

### /drift-loop
```markdown
---
description: Full autonomous QA loop until pixel-perfect
---
Run the complete Drift loop: check → fix → rebuild → re-check → repeat.

Options (passed as args or asked interactively):
- Max iterations (default: 5)
- Severity threshold (default: skip cosmetic-only issues)
- Target screens (default: all)
```

### /drift-report
```markdown
---
description: Generate design compliance report
---
Generate a report from the latest Drift run.
```

---

## Gemini Fallback Strategy

Claude's VLM is the primary analysis model (already included in your Max plan). Gemini is used as a fallback in two cases:

1. **Low confidence results:** If Claude's analysis returns a discrepancy with confidence < 0.5, retry with Gemini for a second opinion. If both models agree → higher confidence. If they disagree → flag for human review.

2. **Batch efficiency:** For runs with 20+ screens, Gemini 1.5 Flash can handle the initial broad-sweep analysis (is this screen roughly correct?) while Claude does the detailed per-discrepancy analysis. This keeps Claude token usage focused on the hard cases.

**Implementation:** The Gemini calls happen via a Python script (`scripts/gemini_analyzer.py`) using the `google-generativeai` SDK. The script is called from Bash, keeping the MCP/tool integration clean.

---

## Timeline Summary

| Phase | Days | What's Working |
|-------|------|----------------|
| 0 — Scaffold | 1–3 | Plugin structure, screen discovery, screenshot capture |
| 1 — Analysis | 4–8 | Full design comparison via Figma MCP + Claude VLM |
| 2 — Auto-Fix | 9–14 | SwiftUI code edits from discrepancy reports |
| 3 — Loop | 15–20 | Autonomous fix-rebuild-recheck cycle |
| 4 — Dashboard | 21–32 | Next.js web app: comparison slider, device frames, real-time progress, code diffs |
| 5 — Productize | 33–38 | Skill integrations, plugin packaging, docs, evals |

**~38 working days** to a shippable plugin with a proper web dashboard.

---

## Risk Register

| Risk | Mitigation |
|------|------------|
| Claude VLM hallucinates non-existent discrepancies | Confidence scoring + Gemini second opinion. Only auto-fix above 0.7. |
| Figma MCP returns stale/wrong frames | Verify frame names match, warn if Figma file hasn't been updated recently |
| Fixes break compilation | Syntax check before commit. Build Agent catches errors. Max 2 fix attempts per issue before marking `wont_fix`. |
| Regression loops (fix A breaks B) | Regression guard with SSIM comparison across ALL screens. Auto-revert on net negative. |
| Screen navigation fails (can't reach all screens) | Fallback to SwiftUI Preview extraction. Manual screen registration as escape hatch. |
| Token cost on large projects | SSIM dedup for captures. Progressive analysis (broad sweep → targeted deep dive). Resolution downsampling before VLM. |

---

## Definition of Done

### Engine MVP (end of Phase 3)

You type `/drift-loop` in Claude Code, and the system:

1. Builds your iOS project to a simulator
2. Captures every discoverable screen
3. Fetches corresponding Figma designs via MCP
4. Compares build vs design using Claude's VLM
5. Produces a discrepancy report with severities and scores
6. Auto-edits SwiftUI source to fix visual discrepancies
7. Git commits the fixes
8. Rebuilds and re-analyzes
9. Checks for regressions across all screens
10. Loops until passing or max iterations
11. Writes structured JSON + screenshots to `drift-reports/`
12. Each iteration is a git commit that can be reviewed or reverted

### Full Product (end of Phase 5)

You type `drift serve`, and at `http://localhost:3000`:

1. Home page shows all historical runs with score trends
2. Click a run → see the tabbed workspace (Comparison, Timeline, Discrepancies, Code Diffs)
3. Comparison tab: side-by-side build vs design with a drag slider, device frame, discrepancy overlays
4. Timeline tab: iteration-by-iteration progress with score deltas
5. Discrepancies tab: full filterable list of every issue, expandable with visual + code diffs
6. Code Diffs tab: git-style syntax-highlighted Swift diffs, grouped by iteration
7. During a live run: real-time progress modal ("Analyzing chunk 2 of 4...") via SSE
8. Settings page: configure Figma file, thresholds, device target
