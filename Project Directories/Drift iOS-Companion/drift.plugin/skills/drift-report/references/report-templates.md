# Report Templates

## Executive Summary Template
```
## Drift Compliance Report — {project_name}

**Score: {score}%** ({status})
**Screens:** {passing}/{total} passing | **Iterations:** {iterations}

### Quick Stats
- {critical_count} critical issues
- {major_count} major issues
- {fixed_count} auto-fixed
- {remaining_count} needs review
```

## Per-Screen Template
```
### {status_icon} {screen_name} — {score}%

**Source:** `{file_path}`

| # | Type | Severity | Element | Expected | Actual | Status |
|---|------|----------|---------|----------|--------|--------|
{discrepancy_rows}
```

## Iteration Summary Template
```
### Iteration {n} — {score}% ({delta:+}%)

**Fixed:** {fixed_count} | **Regressions:** {regression_count} | **Verdict:** {verdict}

Changes:
{change_list}
```
