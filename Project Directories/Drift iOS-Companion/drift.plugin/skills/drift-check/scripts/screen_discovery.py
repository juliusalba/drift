#!/usr/bin/env python3
"""Drift Screen Discovery — Static analysis of SwiftUI View graph."""

import os
import re
import json
import sys
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import Optional


@dataclass
class Screen:
    name: str
    file_path: str
    view_type: str  # root, tab, sheet, navigation, fullscreen
    navigation_parent: Optional[str] = None
    has_preview: bool = False


def find_swift_files(project_dir: str) -> list[Path]:
    """Find all .swift files, excluding build/derived data dirs."""
    exclude = {'.build', 'DerivedData', 'Pods', '.swiftpm', 'Build'}
    results = []
    for root, dirs, files in os.walk(project_dir):
        dirs[:] = [d for d in dirs if d not in exclude]
        for f in files:
            if f.endswith('.swift'):
                results.append(Path(root) / f)
    return results


def extract_views(file_path: Path) -> list[dict]:
    """Extract View structs from a Swift file."""
    content = file_path.read_text(errors='replace')
    views = []

    view_pattern = re.compile(
        r'struct\s+(\w+)\s*:\s*[^{]*\bView\b[^{]*\{',
        re.MULTILINE
    )

    for match in view_pattern.finditer(content):
        name = match.group(1)
        if name.endswith('_Previews') or name == 'Previews':
            continue

        has_preview = bool(re.search(r'#Preview|PreviewProvider', content))

        views.append({
            'name': name,
            'file_path': str(file_path),
            'has_preview': has_preview,
        })

    return views


def detect_navigation(file_path: Path, view_name: str) -> list[dict]:
    """Detect navigation targets from a view."""
    content = file_path.read_text(errors='replace')
    targets = []

    nav_pattern = re.compile(r'NavigationLink\s*\([^)]*destination\s*:\s*(\w+)\s*\(')
    for m in nav_pattern.finditer(content):
        targets.append({'target': m.group(1), 'type': 'navigation', 'parent': view_name})

    nav_pattern2 = re.compile(r'NavigationLink\s*\{[^}]*?(\w+View)\(\)')
    for m in nav_pattern2.finditer(content):
        targets.append({'target': m.group(1), 'type': 'navigation', 'parent': view_name})

    sheet_pattern = re.compile(r'\.sheet\s*\([^)]*\)\s*\{[^}]*?(\w+View)\s*\(')
    for m in sheet_pattern.finditer(content):
        targets.append({'target': m.group(1), 'type': 'sheet', 'parent': view_name})

    cover_pattern = re.compile(r'\.fullScreenCover\s*\([^)]*\)\s*\{[^}]*?(\w+View)\s*\(')
    for m in cover_pattern.finditer(content):
        targets.append({'target': m.group(1), 'type': 'fullscreen', 'parent': view_name})

    tab_pattern = re.compile(r'TabView[^{]*\{([\s\S]*?)\n\s*\}')
    for m in tab_pattern.finditer(content):
        tab_body = m.group(1)
        tab_views = re.findall(r'(\w+View)\s*\(\)', tab_body)
        for tv in tab_views:
            targets.append({'target': tv, 'type': 'tab', 'parent': view_name})

    return targets


def discover_screens(project_dir: str) -> dict:
    """Main discovery function. Returns structured screen data."""
    swift_files = find_swift_files(project_dir)

    all_views = {}
    all_navigations = []

    for fp in swift_files:
        views = extract_views(fp)
        for v in views:
            all_views[v['name']] = v
            navs = detect_navigation(fp, v['name'])
            all_navigations.extend(navs)

    screens = []
    for name, view in all_views.items():
        nav_info = next((n for n in all_navigations if n['target'] == name), None)
        if nav_info:
            view_type = nav_info['type']
            parent = nav_info['parent']
        else:
            view_type = 'root'
            parent = None

        screens.append(Screen(
            name=name,
            file_path=view['file_path'],
            view_type=view_type,
            navigation_parent=parent,
            has_preview=view['has_preview'],
        ))

    return {
        'project_dir': project_dir,
        'total_screens': len(screens),
        'screens': [asdict(s) for s in screens],
        'navigation_edges': all_navigations,
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: screen_discovery.py <project_directory>")
        sys.exit(1)

    project_dir = sys.argv[1]
    if not os.path.isdir(project_dir):
        print(f"Error: {project_dir} is not a directory")
        sys.exit(1)

    result = discover_screens(project_dir)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
