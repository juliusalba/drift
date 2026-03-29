#!/usr/bin/env python3
"""Drift Frame Capture — Capture simulator screenshots for each screen."""

import subprocess
import json
import os
import sys
import time
from pathlib import Path
from datetime import datetime


def get_booted_device() -> dict | None:
    """Get the currently booted simulator device."""
    result = subprocess.run(
        ['xcrun', 'simctl', 'list', 'devices', 'booted', '-j'],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return None

    data = json.loads(result.stdout)
    for runtime, devices in data.get('devices', {}).items():
        for device in devices:
            if device.get('state') == 'Booted':
                return {
                    'udid': device['udid'],
                    'name': device['name'],
                    'runtime': runtime,
                }
    return None


def boot_simulator(device_type: str = "iPhone 16 Pro") -> dict | None:
    """Boot a simulator if none is running."""
    result = subprocess.run(
        ['xcrun', 'simctl', 'list', 'devices', 'available', '-j'],
        capture_output=True, text=True
    )
    data = json.loads(result.stdout)

    for runtime, devices in data.get('devices', {}).items():
        if 'iOS' not in runtime:
            continue
        for device in devices:
            if device_type in device.get('name', ''):
                udid = device['udid']
                subprocess.run(['xcrun', 'simctl', 'boot', udid], capture_output=True)
                time.sleep(3)
                return {
                    'udid': udid,
                    'name': device['name'],
                    'runtime': runtime,
                }
    return None


def capture_screenshot(device_udid: str, output_path: str, screen_name: str = "screen") -> str:
    """Capture a screenshot from the booted simulator."""
    os.makedirs(output_path, exist_ok=True)
    filename = f"{screen_name}.png"
    filepath = os.path.join(output_path, filename)

    result = subprocess.run(
        ['xcrun', 'simctl', 'io', device_udid, 'screenshot', filepath],
        capture_output=True, text=True
    )

    if result.returncode != 0:
        print(f"Error capturing screenshot: {result.stderr}", file=sys.stderr)
        return ""

    return filepath


def build_project(project_path: str, scheme: str | None = None, device_udid: str | None = None) -> bool:
    """Build the Xcode project for simulator."""
    project_dir = Path(project_path)
    workspace = list(project_dir.glob('*.xcworkspace'))
    xcodeproj = list(project_dir.glob('*.xcodeproj'))

    cmd = ['xcodebuild']

    if workspace:
        cmd.extend(['-workspace', str(workspace[0])])
    elif xcodeproj:
        cmd.extend(['-project', str(xcodeproj[0])])
    else:
        print("No Xcode project found", file=sys.stderr)
        return False

    if scheme:
        cmd.extend(['-scheme', scheme])

    if device_udid:
        cmd.extend(['-destination', f'id={device_udid}'])
    else:
        cmd.extend(['-destination', 'generic/platform=iOS Simulator'])

    cmd.extend(['-sdk', 'iphonesimulator', 'build'])

    print(f"Building: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"Build failed:\n{result.stderr[-2000:]}", file=sys.stderr)
        return False

    print("Build succeeded")
    return True


def capture_all_screens(project_dir: str, output_dir: str, screens: list[dict] | None = None) -> dict:
    """Capture screenshots for all discovered screens."""
    device = get_booted_device()
    if not device:
        device = boot_simulator()
    if not device:
        return {'error': 'No simulator available', 'captures': []}

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    capture_dir = os.path.join(output_dir, f'capture-{timestamp}', 'screens')
    os.makedirs(capture_dir, exist_ok=True)

    captures = []

    if screens:
        for screen in screens:
            filepath = capture_screenshot(device['udid'], capture_dir, screen['name'])
            if filepath:
                captures.append({
                    'screen_name': screen['name'],
                    'file_path': filepath,
                    'device': device['name'],
                    'timestamp': timestamp,
                })
    else:
        filepath = capture_screenshot(device['udid'], capture_dir, 'current')
        if filepath:
            captures.append({
                'screen_name': 'current',
                'file_path': filepath,
                'device': device['name'],
                'timestamp': timestamp,
            })

    return {
        'device': device,
        'capture_dir': capture_dir,
        'total_captures': len(captures),
        'captures': captures,
    }


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Drift Frame Capture')
    parser.add_argument('project_dir', help='Path to the Xcode project')
    parser.add_argument('--output', '-o', default='drift-reports', help='Output directory')
    parser.add_argument('--screens', '-s', help='JSON file with screen list from screen_discovery.py')
    parser.add_argument('--build', '-b', action='store_true', help='Build before capturing')
    parser.add_argument('--scheme', help='Xcode scheme to build')
    args = parser.parse_args()

    device = get_booted_device()
    if not device:
        device = boot_simulator()

    if args.build and device:
        success = build_project(args.project_dir, args.scheme, device['udid'])
        if not success:
            sys.exit(1)

    screens = None
    if args.screens:
        with open(args.screens) as f:
            data = json.load(f)
            screens = data.get('screens', [])

    result = capture_all_screens(args.project_dir, args.output, screens)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
