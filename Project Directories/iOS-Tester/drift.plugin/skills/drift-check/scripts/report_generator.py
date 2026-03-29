#!/usr/bin/env python3
"""Drift Report Generator — HTML/Markdown report with visual diffs."""

import json
import os
import sys
from datetime import datetime
from pathlib import Path


def generate_markdown_report(run_data: dict, output_dir: str) -> str:
    """Generate a Markdown compliance report."""
    os.makedirs(output_dir, exist_ok=True)

    summary = run_data.get('summary', {})
    screens = run_data.get('screens', [])
    iterations = run_data.get('iterations', [])

    lines = [
        f"# Drift Compliance Report",
        f"",
        f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Project:** {run_data.get('project_name', 'Unknown')}",
        f"**Overall Score:** {summary.get('overall_score', 0):.0%}",
        f"**Iterations:** {summary.get('total_iterations', 0)}",
        f"**Status:** {summary.get('status', 'unknown')}",
        f"",
        f"---",
        f"",
        f"## Summary",
        f"",
        f"| Metric | Value |",
        f"|--------|-------|",
        f"| Total Screens | {summary.get('total_screens', 0)} |",
        f"| Passing | {summary.get('passing_screens', 0)} |",
        f"| Needs Review | {summary.get('review_screens', 0)} |",
        f"| Critical Issues | {summary.get('critical_issues', 0)} |",
        f"| Major Issues | {summary.get('major_issues', 0)} |",
        f"| Auto-Fixed | {summary.get('auto_fixed', 0)} |",
        f"",
        f"---",
        f"",
        f"## Per-Screen Results",
        f"",
    ]

    for screen in screens:
        score = screen.get('score', 0)
        status = "pass" if score >= 0.9 else "warn" if score >= 0.7 else "fail"
        icon = {"pass": "V", "warn": "!", "fail": "X"}[status]
        lines.append(f"### [{icon}] {screen.get('name', 'Unknown')}")
        lines.append(f"")
        lines.append(f"**Score:** {score:.0%}")
        lines.append(f"**File:** `{screen.get('file_path', '')}`")
        lines.append(f"")

        discrepancies = screen.get('discrepancies', [])
        if discrepancies:
            lines.append(f"| Type | Severity | Element | Status |")
            lines.append(f"|------|----------|---------|--------|")
            for d in discrepancies:
                lines.append(f"| {d.get('type', '')} | {d.get('severity', '')} | {d.get('element', '')} | {d.get('status', 'open')} |")
            lines.append(f"")

    if iterations:
        lines.extend([
            f"---",
            f"",
            f"## Iteration History",
            f"",
            f"| # | Score | Delta | Issues Fixed | Regressions |",
            f"|---|-------|-------|-------------|-------------|",
        ])
        for it in iterations:
            lines.append(
                f"| {it.get('number', '?')} | {it.get('score', 0):.0%} | "
                f"{it.get('delta', 0):+.0%} | {it.get('fixed', 0)} | {it.get('regressions', 0)} |"
            )

    report_text = '\n'.join(lines)
    report_path = os.path.join(output_dir, 'report.md')
    with open(report_path, 'w') as f:
        f.write(report_text)

    return report_path


def generate_html_report(run_data: dict, output_dir: str) -> str:
    """Generate an HTML compliance report."""
    os.makedirs(output_dir, exist_ok=True)

    summary = run_data.get('summary', {})
    score = summary.get('overall_score', 0)
    score_pct = f"{score:.0%}"

    score_color = '#22c55e' if score >= 0.9 else '#f59e0b' if score >= 0.7 else '#ef4444'

    screens_html = ""
    for screen in run_data.get('screens', []):
        s = screen.get('score', 0)
        cls = 'pass' if s >= 0.9 else 'warn' if s >= 0.7 else 'fail'
        color = '#22c55e' if s >= 0.9 else '#f59e0b' if s >= 0.7 else '#ef4444'
        icon = 'V' if s >= 0.9 else '!' if s >= 0.7 else 'X'
        screens_html += f"""
            <div class="screen-card">
                <div class="name">
                    <span class="badge {cls}">{icon}</span>
                    {screen.get('name', 'Unknown')}
                    <span style="margin-left:auto; color:#737373; font-size:0.875rem;">{s:.0%}</span>
                </div>
                <div class="score-bar">
                    <div class="fill" style="width:{s*100}%; background:{color};"></div>
                </div>
            </div>"""

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Drift Report — {run_data.get('project_name', 'Project')}</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0a0a0a; color: #e5e5e5; }}
        .container {{ max-width: 1200px; margin: 0 auto; padding: 2rem; }}
        .header {{ text-align: center; padding: 3rem 0; border-bottom: 1px solid #262626; }}
        .header h1 {{ font-size: 2rem; font-weight: 600; margin-bottom: 0.5rem; }}
        .header .meta {{ color: #737373; font-size: 0.875rem; }}
        .score-ring {{ width: 120px; height: 120px; margin: 2rem auto; position: relative; }}
        .score-ring svg {{ transform: rotate(-90deg); }}
        .score-ring .value {{ position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); font-size: 1.5rem; font-weight: 700; }}
        .stats {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; margin: 2rem 0; }}
        .stat {{ background: #171717; border: 1px solid #262626; border-radius: 0.75rem; padding: 1.5rem; text-align: center; }}
        .stat .number {{ font-size: 2rem; font-weight: 700; color: #fff; }}
        .stat .label {{ color: #737373; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; margin-top: 0.25rem; }}
        .screens {{ margin-top: 2rem; }}
        .screen-card {{ background: #171717; border: 1px solid #262626; border-radius: 0.75rem; padding: 1.5rem; margin-bottom: 1rem; }}
        .screen-card .name {{ font-size: 1.125rem; font-weight: 600; display: flex; align-items: center; gap: 0.5rem; }}
        .screen-card .score-bar {{ height: 4px; background: #262626; border-radius: 2px; margin-top: 0.75rem; overflow: hidden; }}
        .screen-card .score-bar .fill {{ height: 100%; border-radius: 2px; }}
        .badge {{ padding: 0.125rem 0.5rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 500; }}
        .badge.pass {{ background: rgba(34,197,94,0.1); color: #22c55e; }}
        .badge.warn {{ background: rgba(245,158,11,0.1); color: #f59e0b; }}
        .badge.fail {{ background: rgba(239,68,68,0.1); color: #ef4444; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Drift Report</h1>
            <p class="meta">{run_data.get('project_name', 'Project')} &middot; {datetime.now().strftime('%b %d, %Y %I:%M %p')}</p>
            <div class="score-ring">
                <svg width="120" height="120">
                    <circle cx="60" cy="60" r="52" fill="none" stroke="#262626" stroke-width="8"/>
                    <circle cx="60" cy="60" r="52" fill="none" stroke="{score_color}"
                            stroke-width="8" stroke-linecap="round"
                            stroke-dasharray="{score * 326.7} 326.7"/>
                </svg>
                <span class="value">{score_pct}</span>
            </div>
        </div>
        <div class="stats">
            <div class="stat"><div class="number">{summary.get('total_screens', 0)}</div><div class="label">Screens</div></div>
            <div class="stat"><div class="number">{summary.get('passing_screens', 0)}</div><div class="label">Passing</div></div>
            <div class="stat"><div class="number">{summary.get('auto_fixed', 0)}</div><div class="label">Auto-Fixed</div></div>
            <div class="stat"><div class="number">{summary.get('total_iterations', 0)}</div><div class="label">Iterations</div></div>
        </div>
        <div class="screens">
            <h2 style="font-size: 1.25rem; margin-bottom: 1rem;">Screens</h2>
            {screens_html}
        </div>
    </div>
</body>
</html>"""

    report_path = os.path.join(output_dir, 'report.html')
    with open(report_path, 'w') as f:
        f.write(html)

    return report_path


def generate_run_json(run_data: dict, output_dir: str) -> str:
    """Write machine-readable run data."""
    os.makedirs(output_dir, exist_ok=True)
    json_path = os.path.join(output_dir, 'data.json')
    with open(json_path, 'w') as f:
        json.dump(run_data, f, indent=2)
    return json_path


def create_sample_run() -> dict:
    """Create a sample run for testing the dashboard."""
    return {
        'id': 'run-001',
        'project_name': 'iOS-Tester',
        'timestamp': datetime.now().isoformat(),
        'summary': {
            'overall_score': 0.87,
            'total_screens': 6,
            'passing_screens': 4,
            'review_screens': 2,
            'critical_issues': 0,
            'major_issues': 3,
            'auto_fixed': 5,
            'total_iterations': 3,
            'status': 'acceptable',
        },
        'screens': [
            {'name': 'HomeView', 'score': 0.95, 'file_path': 'Sources/Views/HomeView.swift', 'discrepancies': []},
            {'name': 'ProfileView', 'score': 0.92, 'file_path': 'Sources/Views/ProfileView.swift', 'discrepancies': []},
            {'name': 'SettingsView', 'score': 0.91, 'file_path': 'Sources/Views/SettingsView.swift', 'discrepancies': []},
            {'name': 'TransactionsView', 'score': 0.93, 'file_path': 'Sources/Views/TransactionsView.swift', 'discrepancies': []},
            {
                'name': 'LoginView', 'score': 0.78, 'file_path': 'Sources/Views/LoginView.swift',
                'discrepancies': [
                    {'type': 'color', 'severity': 'major', 'element': 'CTA Button', 'expected': '#377CC8', 'actual': '#3A7BC8', 'status': 'fixed', 'confidence': 0.85},
                    {'type': 'spacing', 'severity': 'major', 'element': 'Header padding', 'expected': '16pt', 'actual': '12pt', 'status': 'fixed', 'confidence': 0.9},
                    {'type': 'typography', 'severity': 'minor', 'element': 'Subtitle', 'expected': 'SF Pro Medium 14', 'actual': 'SF Pro Regular 14', 'status': 'open', 'confidence': 0.72},
                ]
            },
            {
                'name': 'OnboardingView', 'score': 0.72, 'file_path': 'Sources/Views/OnboardingView.swift',
                'discrepancies': [
                    {'type': 'layout', 'severity': 'major', 'element': 'Card stack', 'expected': 'Horizontal scroll', 'actual': 'Vertical list', 'status': 'open', 'confidence': 0.65},
                    {'type': 'spacing', 'severity': 'minor', 'element': 'Bottom CTA margin', 'expected': '24pt', 'actual': '20pt', 'status': 'fixed', 'confidence': 0.88},
                ]
            },
        ],
        'iterations': [
            {'number': 1, 'score': 0.71, 'delta': 0, 'fixed': 0, 'regressions': 0},
            {'number': 2, 'score': 0.82, 'delta': 0.11, 'fixed': 3, 'regressions': 0},
            {'number': 3, 'score': 0.87, 'delta': 0.05, 'fixed': 2, 'regressions': 0},
        ],
    }


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Drift Report Generator')
    parser.add_argument('--data', '-d', help='Path to run data JSON')
    parser.add_argument('--output', '-o', default='drift-reports', help='Output directory')
    parser.add_argument('--format', '-f', choices=['md', 'html', 'both', 'json'], default='both')
    parser.add_argument('--sample', action='store_true', help='Generate a sample report for testing')
    args = parser.parse_args()

    if args.sample:
        run_data = create_sample_run()
    elif args.data:
        with open(args.data) as f:
            run_data = json.load(f)
    else:
        print("Provide --data or --sample", file=sys.stderr)
        sys.exit(1)

    output_dir = os.path.join(args.output, f"run-{run_data.get('id', 'unknown')}")

    if args.format in ('md', 'both'):
        md_path = generate_markdown_report(run_data, output_dir)
        print(f"Markdown report: {md_path}")

    if args.format in ('html', 'both'):
        html_path = generate_html_report(run_data, output_dir)
        print(f"HTML report: {html_path}")

    json_path = generate_run_json(run_data, output_dir)
    print(f"Data: {json_path}")


if __name__ == '__main__':
    main()
