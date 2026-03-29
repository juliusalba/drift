# Drift — Design Compliance QA Plugin

Drift is an autonomous design-compliance QA agent for iOS apps. It builds your project, captures every screen, cross-references Figma designs, fixes SwiftUI code, and loops until pixel-perfect.

## Available Commands

- `/drift-check` — Run a single analysis pass (build -> capture -> compare -> report)
- `/drift-fix` — Auto-fix design discrepancies found by drift-check
- `/drift-loop` — Full autonomous loop: check -> fix -> rebuild -> re-check -> repeat
- `/drift-report` — Generate/view compliance report from the latest run

## Key Principles

1. **Visual-only edits**: Drift only modifies visual properties (colors, spacing, fonts, layout, sizing, shape). Never touch business logic.
2. **Regression guarding**: Every iteration compares ALL screens against the previous iteration. Net-negative changes get reverted.
3. **Confidence thresholds**: Only auto-fix discrepancies with confidence > 0.7. Lower confidence items get flagged as comments.
4. **Git safety**: Every iteration is a separate commit that can be reviewed or reverted.

## Data Directory

All reports, screenshots, and analysis data are written to `drift-reports/` in the project root.

## MCP Dependencies

- **Figma MCP** (required): Fetches design frames and design tokens
- **Refero MCP** (optional): Reference screen library for visual matching
