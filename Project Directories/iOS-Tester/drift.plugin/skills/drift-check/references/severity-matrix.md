# Severity Classification Matrix

| Type | Critical | Major | Minor | Cosmetic |
|------|----------|-------|-------|----------|
| **Color** | Completely wrong color scheme | Hex diff > 10% per channel | Hex diff 5-10% | Hex diff < 5% |
| **Spacing** | Layout broken/overlapping | > 4pt difference | 2-4pt difference | < 2pt difference |
| **Typography** | Wrong text content | Wrong font family or size > 2pt | Wrong weight or size 1-2pt | Kerning, line-height < 1pt |
| **Layout** | Missing section, wrong order | Wrong alignment direction | Slight misalignment | Subpixel alignment |
| **Element** | Missing or extra element | Wrong element type | Wrong element state | Wrong animation/transition |
| **Content** | Missing/wrong text | Truncated text | Capitalization | Placeholder vs final |

## Auto-Fix Eligibility

| Severity | Auto-Fix? | Condition |
|----------|-----------|-----------|
| Critical | NO | Always flag for human review |
| Major | YES | If confidence >= 0.8 and visual-only |
| Minor | YES | If confidence >= 0.7 |
| Cosmetic | SKIP | Don't fix unless explicitly requested |
