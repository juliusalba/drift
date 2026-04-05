"""
Drift Image Effects Engine

Applies visual effects to stock photos for iOS app assets.
All effects are non-destructive — originals are preserved.
Uses numpy for vectorized operations (100x faster than pixel loops).

Usage:
    python3 image_effects.py <input> <output> --effect <name> [--params key=value ...]
    python3 image_effects.py --list-presets
    python3 image_effects.py --list-effects
"""

import argparse
import sys
import os
import json
import math

import numpy as np
from PIL import Image, ImageFilter, ImageEnhance, ImageDraw


# ─── Individual Effects (numpy-vectorized) ───────────────────────────

def apply_grain(img: Image.Image, intensity: float = 0.15, **_) -> Image.Image:
    """Add film grain noise using numpy."""
    arr = np.array(img, dtype=np.float32)
    noise = np.random.normal(0, intensity * 255, arr.shape[:2])
    # Apply same noise to R, G, B channels
    for c in range(min(3, arr.shape[2])):
        arr[:, :, c] = np.clip(arr[:, :, c] + noise, 0, 255)
    return Image.fromarray(arr.astype(np.uint8), img.mode)


def apply_duotone(img: Image.Image, dark: tuple = (20, 0, 40), light: tuple = (255, 200, 100), **_) -> Image.Image:
    """Map image to two colors based on luminance using numpy."""
    gray = np.array(img.convert('L'), dtype=np.float32) / 255.0
    h, w = gray.shape

    result = np.zeros((h, w, 3), dtype=np.float32)
    for c in range(3):
        result[:, :, c] = dark[c] * (1 - gray) + light[c] * gray

    if img.mode == 'RGBA':
        alpha = np.array(img)[:, :, 3:]
        result = np.concatenate([result, alpha.astype(np.float32)], axis=2)
        return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8), 'RGBA')
    return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8), 'RGB')


def apply_gradient_overlay(
    img: Image.Image,
    color_start: tuple = (0, 0, 0, 200),
    color_end: tuple = (0, 0, 0, 0),
    direction: str = "bottom",
    **_,
) -> Image.Image:
    """Apply a gradient color overlay using numpy."""
    result = img.convert('RGBA')
    arr = np.array(result, dtype=np.float32)
    h, w = arr.shape[:2]

    if direction in ("bottom", "top"):
        t = np.linspace(0, 1, h).reshape(-1, 1)
        if direction == "top":
            t = 1 - t
    else:
        t = np.linspace(0, 1, w).reshape(1, -1)
        if direction == "left":
            t = 1 - t

    overlay = np.zeros((h, w, 4), dtype=np.float32)
    for c in range(4):
        overlay[:, :, c] = color_start[c] * (1 - t) + color_end[c] * t

    # Alpha composite
    src_a = overlay[:, :, 3:4] / 255.0
    dst_a = arr[:, :, 3:4] / 255.0
    out_a = src_a + dst_a * (1 - src_a)
    safe_a = np.where(out_a > 0, out_a, 1)

    for c in range(3):
        arr[:, :, c] = (overlay[:, :, c] * src_a[:, :, 0] + arr[:, :, c] * dst_a[:, :, 0] * (1 - src_a[:, :, 0])) / safe_a[:, :, 0]
    arr[:, :, 3] = out_a[:, :, 0] * 255

    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), 'RGBA')


def apply_blur(img: Image.Image, radius: float = 5.0, **_) -> Image.Image:
    """Apply Gaussian blur."""
    return img.filter(ImageFilter.GaussianBlur(radius=radius))


def apply_vignette(img: Image.Image, intensity: float = 0.5, radius: float = 0.8, **_) -> Image.Image:
    """Darken edges with a radial falloff using numpy."""
    result = img.convert('RGBA')
    arr = np.array(result, dtype=np.float32)
    h, w = arr.shape[:2]

    # Create distance map from center
    y, x = np.ogrid[:h, :w]
    cx, cy = w / 2, h / 2
    max_dist = math.sqrt(cx ** 2 + cy ** 2)
    dist = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / max_dist

    # Compute vignette alpha
    alpha = np.clip(intensity * np.maximum(0, (dist - radius) / (1 - radius)), 0, 1)

    # Darken RGB channels
    for c in range(3):
        arr[:, :, c] = arr[:, :, c] * (1 - alpha)

    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), 'RGBA')


def apply_color_grade(
    img: Image.Image,
    temperature: float = 0.0,
    tint: float = 0.0,
    contrast: float = 1.0,
    saturation: float = 1.0,
    brightness: float = 1.0,
    **_,
) -> Image.Image:
    """Apply color grading using PIL enhancers + numpy for temp/tint."""
    result = img.copy()

    if brightness != 1.0:
        result = ImageEnhance.Brightness(result).enhance(brightness)
    if contrast != 1.0:
        result = ImageEnhance.Contrast(result).enhance(contrast)
    if saturation != 1.0:
        result = ImageEnhance.Color(result).enhance(saturation)

    if temperature != 0 or tint != 0:
        arr = np.array(result, dtype=np.float32)
        if arr.shape[2] >= 3:
            arr[:, :, 0] = np.clip(arr[:, :, 0] + temperature * 30, 0, 255)  # Red
            arr[:, :, 2] = np.clip(arr[:, :, 2] - temperature * 30, 0, 255)  # Blue
            arr[:, :, 1] = np.clip(arr[:, :, 1] - tint * 20, 0, 255)         # Green
        result = Image.fromarray(arr.astype(np.uint8), result.mode)

    return result


def apply_desaturate(img: Image.Image, amount: float = 0.5, **_) -> Image.Image:
    """Partially desaturate."""
    return ImageEnhance.Color(img).enhance(1 - amount)


def apply_overlay(img: Image.Image, color: tuple = (0, 0, 0), opacity: float = 0.3, **_) -> Image.Image:
    """Solid color overlay with opacity using numpy."""
    result = img.convert('RGBA')
    arr = np.array(result, dtype=np.float32)

    for c in range(3):
        arr[:, :, c] = arr[:, :, c] * (1 - opacity) + color[c] * opacity

    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), 'RGBA')


# ─── Presets ─────────────────────────────────────────────────────────

PRESETS = {
    "editorial": [
        ("desaturate", {"amount": 0.3}),
        ("grain", {"intensity": 0.12}),
        ("vignette", {"intensity": 0.4}),
    ],
    "vibrant": [
        ("color_grade", {"temperature": 0.3, "saturation": 1.2, "contrast": 1.1}),
        ("grain", {"intensity": 0.06}),
    ],
    "moody": [
        ("duotone", {"dark": (15, 10, 35), "light": (200, 180, 140)}),
        ("vignette", {"intensity": 0.6}),
        ("grain", {"intensity": 0.18}),
    ],
    "minimal": [
        ("desaturate", {"amount": 0.6}),
        ("blur", {"radius": 1.5}),
        ("color_grade", {"brightness": 1.05, "contrast": 0.95}),
    ],
    "hero": [
        ("gradient_overlay", {
            "color_start": (0, 0, 0, 200),
            "color_end": (0, 0, 0, 0),
            "direction": "bottom",
        }),
        ("vignette", {"intensity": 0.3}),
    ],
    "dark_ui": [
        ("overlay", {"color": (0, 0, 0), "opacity": 0.4}),
        ("desaturate", {"amount": 0.2}),
        ("grain", {"intensity": 0.08}),
    ],
    "warm_glow": [
        ("color_grade", {"temperature": 0.6, "saturation": 1.1, "brightness": 1.05}),
        ("vignette", {"intensity": 0.35}),
        ("grain", {"intensity": 0.05}),
    ],
    "cool_tone": [
        ("color_grade", {"temperature": -0.5, "saturation": 0.9, "contrast": 1.1}),
        ("grain", {"intensity": 0.08}),
    ],
}

EFFECTS = {
    "grain": apply_grain,
    "duotone": apply_duotone,
    "gradient_overlay": apply_gradient_overlay,
    "blur": apply_blur,
    "vignette": apply_vignette,
    "color_grade": apply_color_grade,
    "desaturate": apply_desaturate,
    "overlay": apply_overlay,
}


# ─── Apply Pipeline ─────────────────────────────────────────────────

def apply_pipeline(img: Image.Image, steps: list) -> Image.Image:
    """Apply a list of (effect_name, params) steps."""
    result = img
    for name, params in steps:
        fn = EFFECTS.get(name)
        if fn:
            result = fn(result, **params)
    return result


# ─── iOS Asset Export ────────────────────────────────────────────────

def export_for_ios(img: Image.Image, output_dir: str, name: str):
    """Export image at 1x, 2x, 3x for iOS asset catalog."""
    os.makedirs(output_dir, exist_ok=True)

    w, h = img.size
    base_w = min(w, 390)
    scale_factor = base_w / w
    base_h = int(h * scale_factor)

    scales = {"1x": 1, "2x": 2, "3x": 3}
    filenames = {}

    for label, mult in scales.items():
        sw, sh = int(base_w * mult), int(base_h * mult)
        if sw > w or sh > h:
            sw, sh = w, h
        resized = img.resize((sw, sh), Image.LANCZOS)
        fname = f"{name}{'@' + label if label != '1x' else ''}.png"
        resized.save(os.path.join(output_dir, fname), "PNG")
        filenames[label] = fname

    contents = {
        "images": [
            {"filename": filenames.get("1x", ""), "idiom": "universal", "scale": "1x"},
            {"filename": filenames.get("2x", ""), "idiom": "universal", "scale": "2x"},
            {"filename": filenames.get("3x", ""), "idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "drift", "version": 1},
    }
    with open(os.path.join(output_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)


# ─── CLI ─────────────────────────────────────────────────────────────

def parse_param(val: str):
    """Parse a CLI param value to the right type."""
    if val.lower() in ('true', 'false'):
        return val.lower() == 'true'
    try:
        if '.' in val:
            return float(val)
        return int(val)
    except ValueError:
        if ',' in val:
            try:
                return tuple(int(x.strip()) for x in val.split(','))
            except ValueError:
                pass
        return val


def main():
    parser = argparse.ArgumentParser(description="Drift Image Effects Engine")
    parser.add_argument("input", nargs="?", help="Input image path")
    parser.add_argument("output", nargs="?", help="Output path")
    parser.add_argument("--effect", action="append", help="Effect to apply (can repeat)")
    parser.add_argument("--preset", help="Named preset to apply")
    parser.add_argument("--params", nargs="*", help="Effect params as key=value")
    parser.add_argument("--ios-export", action="store_true", help="Export as iOS asset catalog imageset")
    parser.add_argument("--asset-name", default="image", help="Asset name for iOS export")
    parser.add_argument("--list-presets", action="store_true", help="List all presets")
    parser.add_argument("--list-effects", action="store_true", help="List all effects")

    args = parser.parse_args()

    if args.list_presets:
        print("Available presets:")
        for name, steps in PRESETS.items():
            effects_str = " → ".join(s[0] for s in steps)
            print(f"  {name}: {effects_str}")
        return

    if args.list_effects:
        print("Available effects:")
        for name in EFFECTS:
            print(f"  {name}")
        return

    if not args.input or not args.output:
        parser.error("input and output are required (unless using --list-presets or --list-effects)")

    # Load image
    if not os.path.isfile(args.input):
        print(f"Error: Input file not found: {args.input}")
        sys.exit(1)

    try:
        img = Image.open(args.input)
        if img.mode not in ('RGB', 'RGBA'):
            img = img.convert('RGBA')
        print(f"Loaded {args.input} ({img.size[0]}x{img.size[1]}, {img.mode})")
    except Exception as e:
        print(f"Error: Could not open image: {e}")
        sys.exit(1)

    # Build pipeline
    steps = []

    if args.preset:
        if args.preset not in PRESETS:
            print(f"Unknown preset: {args.preset}")
            print(f"Available: {', '.join(PRESETS.keys())}")
            sys.exit(1)
        steps.extend(PRESETS[args.preset])
        print(f"Using preset: {args.preset}")

    if args.effect:
        params = {}
        if args.params:
            for p in args.params:
                if '=' not in p:
                    print(f"Warning: Skipping invalid param '{p}' (expected key=value)")
                    continue
                k, v = p.split('=', 1)
                params[k] = parse_param(v)

        for effect_name in args.effect:
            if effect_name not in EFFECTS:
                print(f"Unknown effect: {effect_name}")
                sys.exit(1)
            steps.append((effect_name, params))

    if not steps:
        print("No effects or preset specified. Use --effect or --preset.")
        sys.exit(1)

    # Apply
    result = apply_pipeline(img, steps)

    # Export
    try:
        if args.ios_export:
            export_for_ios(result, args.output, args.asset_name)
        else:
            result.save(args.output)
            print(f"Saved to {args.output}")
    except Exception as e:
        print(f"Error saving output: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
