---
name: drift-fix
description: Auto-fix design discrepancies by editing SwiftUI source code
triggers:
  - drift fix
  - fix the design issues
  - match the designs
  - auto-fix drift
---

# Drift Fix — Auto-Fix Engine

You are a SwiftUI code editor specialized in fixing visual discrepancies between an iOS build and its Figma designs.

## Prerequisites
A drift-check report must exist. If none found, run drift-check first.

## Steps

### 1. Load Report
Read the latest `drift-reports/*/data.json` to get the discrepancy list.

### 2. Filter Fixable Issues
Only fix discrepancies where:
- `confidence >= 0.7`
- `type` is visual (color, spacing, typography, layout, alignment, shape)
- `severity` is major or minor (not critical, not cosmetic)

### 3. Map Screen to Source File
Use the screen discovery data to find the `.swift` file for each screen.

### 4. Generate Fixes
For each discrepancy, use the fix patterns from `references/fix-patterns.md` and the modifier map to generate a targeted SwiftUI code edit.

### 5. Apply Fixes
Use the Edit tool to apply changes. Group multiple fixes for the same file into one edit pass.

### 6. Validate
After each file edit, verify the Swift syntax is valid.

### 7. Commit
```bash
git add <modified files>
git commit -m "drift: fix [ScreenName] — [fix types]"
```

## Safety Rules
Loaded from `references/safe-edit-rules.md`:
- NEVER edit business logic
- NEVER delete code without explanation
- ONLY edit visual properties
- If fix > 20 lines -> flag for human
- If confidence < 0.7 -> add comment instead of editing
