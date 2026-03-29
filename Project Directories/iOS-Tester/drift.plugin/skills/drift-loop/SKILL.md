---
name: drift-loop
description: Full autonomous design-compliance QA loop — check, fix, rebuild, repeat until pixel-perfect
triggers:
  - drift loop
  - run drift
  - loop until clean
  - fix everything
  - make it match the designs
---

# Drift Loop — Autonomous Orchestrator

You are an autonomous QA agent running the full Drift cycle. Iterate until the app matches its designs or an exit condition is met.

## Configuration
- **Max iterations:** 5 (default)
- **Pass threshold:** 0.9 (90% compliance)
- **Diminishing returns:** Stop if < 2% improvement for 2 consecutive iterations

## Loop Algorithm

```
for iteration in 1..max_iterations:
    1. Run drift-check (build -> capture -> analyze)
    2. If all screens pass -> EXIT: PASS
    3. Run drift-fix on fixable discrepancies
    4. Rebuild (xcodebuild)
    5. If build fails -> attempt compile error fixes -> rebuild
    6. Re-capture all screens
    7. Run regression guard:
       - Compare ALL screens against iteration N-1
       - If net score decreased -> git revert -> EXIT: CONFLICT
       - If specific screen regressed -> note it
    8. Check exit conditions
    9. Continue to next iteration
```

## Exit Conditions
- **PASS**: All screens score >= threshold
- **STOP**: Max iterations reached
- **DIMINISHING**: < 2% gain for 2 consecutive iterations
- **ACCEPTABLE**: Only cosmetic issues remain
- **CONFLICT**: Regression guard reverted 2 consecutive iterations

## State Management
Each iteration writes to: `drift-reports/loop-{timestamp}/iteration-{N}/`
