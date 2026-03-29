# Loop Strategy

## Iteration Priority
1. Fix critical issues first (broken layout, missing elements)
2. Fix major issues (color, spacing > 4pt, wrong fonts)
3. Fix minor issues (small spacing, weight mismatches)
4. Skip cosmetic issues unless explicitly requested

## Diminishing Returns Detection
Track the score delta per iteration:
- If delta < 2% for 2 consecutive iterations -> stop
- This prevents infinite loops on hard-to-fix issues

## Regression Prevention
- After each fix batch, re-capture ALL screens (not just fixed ones)
- Compare every screen against previous iteration via SSIM
- If a previously-passing screen drops > 5% -> regression
- If total regressions > improvements -> revert the entire iteration

## Build Failure Recovery
If xcodebuild fails after fixes:
1. Parse the error output
2. Common fixes: missing imports, type mismatches, renamed properties
3. Apply compile fixes (max 2 attempts)
4. If still failing -> revert fixes and flag

## Parallel Processing
Use the Agent tool to analyze multiple screens simultaneously when there are > 4 screens.
