#!/usr/bin/env python3
"""Drift Score Tracker — Track compliance scores across runs."""

import json
import os
import sys
from pathlib import Path


def load_run_summaries(reports_dir: str) -> list[dict]:
    """Load summary data from all runs."""
    runs = []
    reports_path = Path(reports_dir)

    if not reports_path.exists():
        return runs

    for run_dir in sorted(reports_path.iterdir()):
        if not run_dir.is_dir() or not run_dir.name.startswith('run-'):
            continue

        data_file = run_dir / 'data.json'
        if not data_file.exists():
            continue

        with open(data_file) as f:
            data = json.load(f)

        runs.append({
            'id': data.get('id', run_dir.name),
            'project': data.get('project_name', 'Unknown'),
            'timestamp': data.get('timestamp', ''),
            'overall_score': data.get('summary', {}).get('overall_score', 0),
            'total_screens': data.get('summary', {}).get('total_screens', 0),
            'passing_screens': data.get('summary', {}).get('passing_screens', 0),
            'status': data.get('summary', {}).get('status', 'unknown'),
            'iterations': data.get('summary', {}).get('total_iterations', 0),
        })

    return runs


def generate_trend(reports_dir: str) -> dict:
    """Generate trend data across runs."""
    runs = load_run_summaries(reports_dir)

    if not runs:
        return {'trend': [], 'average': 0, 'best': 0, 'latest': 0}

    scores = [r['overall_score'] for r in runs]

    return {
        'runs': runs,
        'trend': scores,
        'average': round(sum(scores) / len(scores), 4),
        'best': max(scores),
        'latest': scores[-1] if scores else 0,
        'total_runs': len(runs),
        'improving': len(scores) >= 2 and scores[-1] > scores[-2],
    }


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Drift Score Tracker')
    parser.add_argument('reports_dir', help='Path to drift-reports directory')
    args = parser.parse_args()

    result = generate_trend(args.reports_dir)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
