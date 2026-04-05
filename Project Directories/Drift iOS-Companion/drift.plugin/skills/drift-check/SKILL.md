---
name: drift-check
description: Run a single design compliance analysis pass — build, capture, compare, report
triggers:
  - drift check
  - check designs
  - compare to Figma
  - design audit
  - how close is this to the designs
---

# Drift Check — Single Analysis Pass

You are a design-compliance QA specialist. Run a single pass to compare the built iOS app against its Figma designs.

## Steps

### 1. Locate the Project
Find the Xcode project (`.xcodeproj` or `.xcworkspace`) in the current workspace.

### 2. Discover Screens
Run `screen_discovery.py` to find all SwiftUI View structs and map the navigation graph.
```bash
python3 drift.plugin/skills/drift-check/scripts/screen_discovery.py .
```

### 3. Build to Simulator
```bash
xcodebuild -project <project>.xcodeproj -scheme <scheme> -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -sdk iphonesimulator build
```
If build fails, report the errors and stop.

### 4. Capture Screenshots
Use `frame_capture.py` or directly:
```bash
xcrun simctl io booted screenshot drift-reports/screens/<ScreenName>.png
```

### 5. Fetch Design References
In order of preference:
1. **Figma MCP**: Use `get_design_context` or `get_screenshot` to fetch design frames
2. **Refero MCP**: Use `refero_search_screens` to find matching reference screens
3. **Local designs/**: Check for PNGs in a `designs/` folder in the project root

### 6. Match Screens to Designs
Match by name first. For ambiguous cases, use VLM to visually match screenshots to design frames.

### 7. Analyze Each Pair
For each (build screenshot, design reference) pair, analyze using the prompts from `references/analysis-prompts.md`.

### 8. Generate Report
Use `report_generator.py` to create the compliance report in `drift-reports/`.

## Output
Creates `drift-reports/check-{timestamp}/` with:
- `report.md` — Full Markdown report
- `report.html` — Interactive HTML report
- `screens/` — Captured screenshots
- `diffs/` — Side-by-side comparisons
- `data.json` — Machine-readable discrepancy data
