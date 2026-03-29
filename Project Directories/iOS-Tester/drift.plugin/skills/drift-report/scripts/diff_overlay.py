#!/usr/bin/env python3
"""Drift Diff Overlay — Side-by-side screenshot overlay generator."""

import sys
import os

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False


def create_side_by_side(build_path: str, design_path: str, output_path: str, gap: int = 20) -> str:
    """Create a side-by-side comparison image."""
    if not HAS_PIL:
        return ""

    build = Image.open(build_path)
    design = Image.open(design_path)

    max_h = max(build.height, design.height)
    if build.height != max_h:
        ratio = max_h / build.height
        build = build.resize((int(build.width * ratio), max_h), Image.LANCZOS)
    if design.height != max_h:
        ratio = max_h / design.height
        design = design.resize((int(design.width * ratio), max_h), Image.LANCZOS)

    total_w = build.width + gap + design.width
    canvas = Image.new('RGB', (total_w, max_h), (26, 26, 26))
    canvas.paste(build, (0, 0))
    canvas.paste(design, (build.width + gap, 0))

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    canvas.save(output_path)
    return output_path


def create_diff_highlight(build_path: str, design_path: str, output_path: str) -> str:
    """Create a difference highlight overlay."""
    if not HAS_PIL:
        return ""

    build = Image.open(build_path).convert('RGB')
    design = Image.open(design_path).convert('RGB')

    size = (min(build.width, design.width), min(build.height, design.height))
    build = build.resize(size, Image.LANCZOS)
    design = design.resize(size, Image.LANCZOS)

    diff = Image.new('RGB', size)
    build_px = build.load()
    design_px = design.load()
    diff_px = diff.load()

    for x in range(size[0]):
        for y in range(size[1]):
            r1, g1, b1 = build_px[x, y]
            r2, g2, b2 = design_px[x, y]
            dr = abs(r1 - r2)
            dg = abs(g1 - g2)
            db = abs(b1 - b2)
            if dr + dg + db > 30:
                diff_px[x, y] = (min(255, (dr + dg + db) * 3), 0, 0)
            else:
                diff_px[x, y] = (r1 // 3, g1 // 3, b1 // 3)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    diff.save(output_path)
    return output_path


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Drift Diff Overlay')
    parser.add_argument('build', help='Build screenshot')
    parser.add_argument('design', help='Design reference')
    parser.add_argument('--output', '-o', required=True, help='Output path')
    parser.add_argument('--mode', choices=['side-by-side', 'highlight'], default='side-by-side')
    args = parser.parse_args()

    if args.mode == 'side-by-side':
        result = create_side_by_side(args.build, args.design, args.output)
    else:
        result = create_diff_highlight(args.build, args.design, args.output)

    if result:
        print(f"Output: {result}")
    else:
        print("PIL not available. Install with: pip install Pillow", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
