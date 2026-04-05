# Drift — Design Co-Pilot for iOS

Drift is an autonomous design-compliance QA agent and design co-pilot for iOS apps. It builds your project, captures every screen, cross-references Figma designs, pulls inspiration from real products, sources and processes stock photo assets, fixes SwiftUI code, and loops until pixel-perfect.

## Available Commands

### QA & Compliance
- `/drift-check` — Run a single analysis pass (build → capture → compare → report)
- `/drift-fix` — Auto-fix design discrepancies found by drift-check
- `/drift-loop` — Full autonomous loop: check → fix → rebuild → re-check → repeat
- `/drift-report` — Generate/view compliance report from the latest run

### Design Inspiration
- `/drift-inspire` — Pull design patterns from Refero + 21st.dev, synthesize into SwiftUI
- `/drift-assets` — Find stock photos, apply effects (grain/duotone/gradient), export to Xcode assets

## Key Principles

1. **Visual-only edits**: Drift only modifies visual properties (colors, spacing, fonts, layout, sizing, shape). Never touch business logic.
2. **Regression guarding**: Every iteration compares ALL screens against the previous iteration. Net-negative changes get reverted.
3. **Confidence thresholds**: Only auto-fix discrepancies with confidence > 0.7. Lower confidence items get flagged as comments.
4. **Git safety**: Every iteration is a separate commit that can be reviewed or reverted.
5. **Free assets only**: Stock photos come from Unsplash/Pexels (free commercial license).

## MCP Dependencies

- **Figma MCP** (required): Fetches design frames and design tokens
- **Refero MCP** (recommended): Real-world screen patterns from top apps
- **21st.dev Magic MCP** (optional): Production-ready component inspiration

## Data Directory

All reports, screenshots, and analysis data are written to `drift-reports/` in the project root.

## Companion App

**DriftBar** — Native macOS menu bar app that watches Xcode builds and shows compliance scores inline. Lives in `DriftBar/`.

## Effect Presets (for /drift-assets)

`editorial` · `vibrant` · `moody` · `minimal` · `hero` · `dark_ui` · `warm_glow` · `cool_tone`
