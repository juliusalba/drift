---
name: drift-report
description: Generate and view design compliance reports from Drift runs
triggers:
  - drift report
  - show me the drift results
  - what changed
  - design compliance report
---

# Drift Report — Reporting & Dashboard

Generate visual compliance reports from Drift run data.

## Steps

### 1. Find Latest Run
Look for the most recent data in `drift-reports/`.

### 2. Generate Reports
Use `report_generator.py` to create:
- Markdown summary report
- Interactive HTML report
- Machine-readable JSON data

### 3. Launch Dashboard (if available)
If `drift-dashboard/` exists:
```bash
cd drift-dashboard && npm run dev
```
Then open http://localhost:3000

If no dashboard, output the Markdown report directly.

## Report Contents
- **Executive Summary**: Overall score, screens passing/failing, iterations
- **Per-Screen Detail**: Side-by-side screenshots, discrepancy list
- **Fix Audit Trail**: Every code edit with before/after
- **Remaining Issues**: Unfixed discrepancies with manual fix suggestions
- **Trend Data**: Score history across multiple runs
