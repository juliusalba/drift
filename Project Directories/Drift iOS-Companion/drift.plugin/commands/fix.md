---
description: Auto-fix design discrepancies
---
Fix design discrepancies found by drift-check.

1. Read the latest drift-check report
2. For each fixable discrepancy (confidence > 0.7, visual-only):
   - Map screen -> source file
   - Generate targeted SwiftUI code edit
   - Apply and validate
3. Git commit all fixes
