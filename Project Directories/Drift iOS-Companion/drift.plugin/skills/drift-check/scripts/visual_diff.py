#!/usr/bin/env python3
"""Drift Visual Diff — SSIM + perceptual hash comparison between screenshots."""

import json
import sys
import os
import hashlib
from pathlib import Path

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False


def image_hash(image_path: str, hash_size: int = 16) -> str:
    """Compute a perceptual hash (average hash) for an image."""
    if not HAS_PIL:
        with open(image_path, 'rb') as f:
            return hashlib.md5(f.read()).hexdigest()

    img = Image.open(image_path).convert('L').resize((hash_size, hash_size), Image.LANCZOS)
    pixels = list(img.getdata())
    avg = sum(pixels) / len(pixels)
    bits = ''.join('1' if p > avg else '0' for p in pixels)
    return hex(int(bits, 2))[2:].zfill(hash_size * hash_size // 4)


def hamming_distance(hash1: str, hash2: str) -> int:
    """Compute hamming distance between two hex hashes."""
    if len(hash1) != len(hash2):
        return max(len(hash1), len(hash2)) * 4

    distance = 0
    for c1, c2 in zip(hash1, hash2):
        b1 = int(c1, 16)
        b2 = int(c2, 16)
        distance += bin(b1 ^ b2).count('1')
    return distance


def compute_ssim_simple(img1_path: str, img2_path: str) -> float:
    """Compute a simplified structural similarity between two images."""
    if not HAS_PIL:
        return 0.0

    img1 = Image.open(img1_path).convert('L').resize((256, 256), Image.LANCZOS)
    img2 = Image.open(img2_path).convert('L').resize((256, 256), Image.LANCZOS)

    pixels1 = list(img1.getdata())
    pixels2 = list(img2.getdata())

    n = len(pixels1)
    mean1 = sum(pixels1) / n
    mean2 = sum(pixels2) / n

    var1 = sum((p - mean1) ** 2 for p in pixels1) / n
    var2 = sum((p - mean2) ** 2 for p in pixels2) / n

    covar = sum((p1 - mean1) * (p2 - mean2) for p1, p2 in zip(pixels1, pixels2)) / n

    C1 = (0.01 * 255) ** 2
    C2 = (0.03 * 255) ** 2

    ssim = ((2 * mean1 * mean2 + C1) * (2 * covar + C2)) / \
           ((mean1 ** 2 + mean2 ** 2 + C1) * (var1 + var2 + C2))

    return round(ssim, 4)


def compare_images(build_path: str, design_path: str) -> dict:
    """Compare a build screenshot against a design reference."""
    if not os.path.exists(build_path):
        return {'error': f'Build image not found: {build_path}'}
    if not os.path.exists(design_path):
        return {'error': f'Design image not found: {design_path}'}

    hash1 = image_hash(build_path)
    hash2 = image_hash(design_path)
    distance = hamming_distance(hash1, hash2)
    max_distance = len(hash1) * 4
    hash_similarity = 1.0 - (distance / max_distance) if max_distance > 0 else 0.0

    ssim = compute_ssim_simple(build_path, design_path)

    combined_score = round(0.6 * ssim + 0.4 * hash_similarity, 4)

    return {
        'build_image': build_path,
        'design_image': design_path,
        'ssim': ssim,
        'perceptual_hash_similarity': round(hash_similarity, 4),
        'combined_score': combined_score,
        'hash_distance': distance,
        'needs_vlm_analysis': combined_score < 0.95,
    }


def compare_iterations(prev_dir: str, curr_dir: str) -> dict:
    """Compare screenshots between two iterations for regression detection."""
    prev_path = Path(prev_dir)
    curr_path = Path(curr_dir)

    prev_screens = {f.stem: str(f) for f in prev_path.glob('*.png')}
    curr_screens = {f.stem: str(f) for f in curr_path.glob('*.png')}

    comparisons = []
    regressions = []

    for name in set(prev_screens) & set(curr_screens):
        result = compare_images(curr_screens[name], prev_screens[name])
        result['screen_name'] = name
        comparisons.append(result)

        if result.get('combined_score', 1.0) < 0.85:
            regressions.append(name)

    new_screens = list(set(curr_screens) - set(prev_screens))
    removed_screens = list(set(prev_screens) - set(curr_screens))

    return {
        'comparisons': comparisons,
        'regressions': regressions,
        'new_screens': new_screens,
        'removed_screens': removed_screens,
        'has_regressions': len(regressions) > 0,
    }


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Drift Visual Diff')
    subparsers = parser.add_subparsers(dest='command')

    compare_parser = subparsers.add_parser('compare', help='Compare two images')
    compare_parser.add_argument('build', help='Build screenshot path')
    compare_parser.add_argument('design', help='Design reference path')

    regression_parser = subparsers.add_parser('regression', help='Compare iterations')
    regression_parser.add_argument('prev_dir', help='Previous iteration screenshots')
    regression_parser.add_argument('curr_dir', help='Current iteration screenshots')

    args = parser.parse_args()

    if args.command == 'compare':
        result = compare_images(args.build, args.design)
    elif args.command == 'regression':
        result = compare_iterations(args.prev_dir, args.curr_dir)
    else:
        parser.print_help()
        sys.exit(1)

    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
