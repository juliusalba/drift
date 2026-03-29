#!/usr/bin/env python3
"""Drift Regression Guard — Cross-iteration comparison to detect regressions."""

import json
import sys
import os
from pathlib import Path


def load_iteration_data(iteration_dir: str) -> dict:
    """Load data.json from an iteration directory."""
    data_path = os.path.join(iteration_dir, 'data.json')
    if not os.path.exists(data_path):
        return {}
    with open(data_path) as f:
        return json.load(f)


def compare_scores(prev_data: dict, curr_data: dict) -> dict:
    """Compare scores between two iterations."""
    prev_screens = {s['name']: s for s in prev_data.get('screens', [])}
    curr_screens = {s['name']: s for s in curr_data.get('screens', [])}

    regressions = []
    improvements = []
    unchanged = []

    for name in set(prev_screens) | set(curr_screens):
        prev_score = prev_screens.get(name, {}).get('score', 0)
        curr_score = curr_screens.get(name, {}).get('score', 0)
        delta = curr_score - prev_score

        entry = {
            'screen': name,
            'prev_score': prev_score,
            'curr_score': curr_score,
            'delta': round(delta, 4),
        }

        if delta < -0.05:
            regressions.append(entry)
        elif delta > 0.02:
            improvements.append(entry)
        else:
            unchanged.append(entry)

    prev_overall = prev_data.get('summary', {}).get('overall_score', 0)
    curr_overall = curr_data.get('summary', {}).get('overall_score', 0)
    overall_delta = curr_overall - prev_overall

    return {
        'prev_overall': prev_overall,
        'curr_overall': curr_overall,
        'overall_delta': round(overall_delta, 4),
        'regressions': regressions,
        'improvements': improvements,
        'unchanged': unchanged,
        'verdict': _determine_verdict(overall_delta, regressions),
    }


def _determine_verdict(overall_delta: float, regressions: list) -> str:
    """Determine the iteration verdict."""
    if overall_delta < -0.02 or len(regressions) >= 2:
        return 'REVERT'
    if overall_delta < 0.02 and len(regressions) == 0:
        return 'DIMINISHING'
    if len(regressions) > 0:
        return 'MIXED'
    return 'PASS'


def should_continue(loop_dir: str, max_iterations: int = 5, threshold: float = 0.9) -> dict:
    """Determine if the loop should continue."""
    iterations_dir = os.path.join(loop_dir, 'iterations')
    if not os.path.isdir(iterations_dir):
        return {'continue': True, 'reason': 'no_iterations_yet'}

    iteration_dirs = sorted(Path(iterations_dir).iterdir())
    n = len(iteration_dirs)

    if n >= max_iterations:
        return {'continue': False, 'reason': 'max_iterations', 'iterations': n}

    if n == 0:
        return {'continue': True, 'reason': 'starting'}

    latest = load_iteration_data(str(iteration_dirs[-1]))
    score = latest.get('summary', {}).get('overall_score', 0)

    if score >= threshold:
        return {'continue': False, 'reason': 'threshold_met', 'score': score}

    if n >= 2:
        prev = load_iteration_data(str(iteration_dirs[-2]))
        prev_score = prev.get('summary', {}).get('overall_score', 0)
        delta = score - prev_score

        if n >= 3:
            prev2 = load_iteration_data(str(iteration_dirs[-3]))
            prev2_score = prev2.get('summary', {}).get('overall_score', 0)
            delta2 = prev_score - prev2_score

            if delta < 0.02 and delta2 < 0.02:
                return {'continue': False, 'reason': 'diminishing_returns', 'deltas': [delta2, delta]}

    all_discrepancies = []
    for screen in latest.get('screens', []):
        all_discrepancies.extend(screen.get('discrepancies', []))

    open_issues = [d for d in all_discrepancies if d.get('status') != 'fixed']
    non_cosmetic = [d for d in open_issues if d.get('severity') != 'cosmetic']

    if len(non_cosmetic) == 0 and len(open_issues) > 0:
        return {'continue': False, 'reason': 'cosmetic_only', 'remaining': len(open_issues)}

    return {'continue': True, 'reason': 'issues_remain', 'score': score, 'open_issues': len(open_issues)}


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Drift Regression Guard')
    subparsers = parser.add_subparsers(dest='command')

    compare_parser = subparsers.add_parser('compare', help='Compare two iterations')
    compare_parser.add_argument('prev', help='Previous iteration directory')
    compare_parser.add_argument('curr', help='Current iteration directory')

    check_parser = subparsers.add_parser('should-continue', help='Check if loop should continue')
    check_parser.add_argument('loop_dir', help='Loop directory')
    check_parser.add_argument('--max', type=int, default=5, help='Max iterations')
    check_parser.add_argument('--threshold', type=float, default=0.9, help='Pass threshold')

    args = parser.parse_args()

    if args.command == 'compare':
        prev = load_iteration_data(args.prev)
        curr = load_iteration_data(args.curr)
        result = compare_scores(prev, curr)
    elif args.command == 'should-continue':
        result = should_continue(args.loop_dir, args.max, args.threshold)
    else:
        parser.print_help()
        sys.exit(1)

    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
