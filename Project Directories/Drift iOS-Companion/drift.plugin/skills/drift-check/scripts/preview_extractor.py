#!/usr/bin/env python3
"""Drift Preview Extractor — Find and render SwiftUI Preview blocks."""

import re
import json
import sys
import os
from pathlib import Path


def find_preview_files(project_dir: str) -> list[dict]:
    """Find Swift files containing #Preview or PreviewProvider."""
    results = []
    exclude = {'.build', 'DerivedData', 'Pods', '.swiftpm', 'Build'}

    for root, dirs, files in os.walk(project_dir):
        dirs[:] = [d for d in dirs if d not in exclude]
        for f in files:
            if not f.endswith('.swift'):
                continue
            fp = Path(root) / f
            content = fp.read_text(errors='replace')

            preview_blocks = re.findall(r'#Preview\s*(?:\("([^"]+)"\))?\s*\{', content)
            legacy_previews = re.findall(r'struct\s+(\w+)_Previews?\s*:', content)

            if preview_blocks or legacy_previews:
                view_match = re.search(r'struct\s+(\w+)\s*:\s*[^{]*\bView\b', content)
                view_name = view_match.group(1) if view_match else f.replace('.swift', '')

                results.append({
                    'file_path': str(fp),
                    'view_name': view_name,
                    'preview_names': [p for p in preview_blocks if p] or [view_name],
                    'has_modern_preview': bool(preview_blocks),
                    'has_legacy_preview': bool(legacy_previews),
                })

    return results


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Drift Preview Extractor')
    parser.add_argument('project_dir', help='Path to the Xcode project')
    parser.add_argument('--output', '-o', default='drift-reports/previews', help='Output directory')
    args = parser.parse_args()

    previews = find_preview_files(args.project_dir)

    result = {
        'project_dir': args.project_dir,
        'total_previews': len(previews),
        'previews': previews,
    }

    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
