#!/usr/bin/env python3
"""Drift Dashboard Generator — Generates index.json for the dashboard."""

import json
import os
import sys
from pathlib import Path


def generate_index_json(reports_dir: str) -> str:
    """Generate index.json listing all runs for the dashboard."""
    reports_path = Path(reports_dir)
    runs = []

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
            'project_name': data.get('project_name', 'Unknown'),
            'timestamp': data.get('timestamp', ''),
            'overall_score': data.get('summary', {}).get('overall_score', 0),
            'total_screens': data.get('summary', {}).get('total_screens', 0),
            'passing_screens': data.get('summary', {}).get('passing_screens', 0),
            'status': data.get('summary', {}).get('status', 'unknown'),
            'iterations': data.get('summary', {}).get('total_iterations', 0),
        })

    index_path = os.path.join(reports_dir, 'index.json')
    with open(index_path, 'w') as f:
        json.dump({'runs': runs}, f, indent=2)

    return index_path


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Drift Dashboard Generator')
    parser.add_argument('reports_dir', help='Path to drift-reports directory')
    parser.add_argument('--regenerate', action='store_true', help='Regenerate index')
    args = parser.parse_args()

    index_path = generate_index_json(args.reports_dir)
    print(f"Index generated: {index_path}")


if __name__ == '__main__':
    main()
