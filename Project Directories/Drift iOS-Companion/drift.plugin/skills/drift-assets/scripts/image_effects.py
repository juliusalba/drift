"""
Drift Image Effects Engine

Applies visual effects to stock photos for iOS app assets.
All effects are non-destructive — originals are preserved.

Usage:
    python3 image_effects.py <input> <output> --effect <name> [--params key=value ...]

Effects:
    grain       - Film grain texture overlay
    duotone     - Two-color tonal mapping
    gradient    - Gradient color overlay (top-to-bottom or radial)
    blur        - Gaussian or lens blur
    vignette    - Darkened edges, bright center
    color_grade - Lift/gamma/gain color grading
    desaturate  - Partial or full desaturation
    overlay     - Color overlay with blend mode

Presets (combine multiple effects):
    --preset editorial    : desaturate(0.3) + grain(0.15) + vignette(0.4)
    --preset vibrant      : color_grade(warm) + grain(0.08)
    --preset moody        : duotone(dark) + vignette(0.6) + grain(0.2)
    --preset minimal      : desaturate(0.6) + blur(2)
    --preset hero         : gradient(bottom_fade) + vignette(0.3)
"""

import argparse
import sys
import os
import json
import random
import math

from PIL import Image, ImageFilter, ImageEnhance, ImageDraw


# ─── Individual Effects ──────────────────────────────────────────────

def apply_grain(img: Image.Image, intensity: float = 0.15, size: int = 1) -> Image.Image:
    """Add film grain noise."""
    result = img.copy()
    pixels = result.load()
    w, h = result.size

    for y in range(0, h, size):
        for x in range(0, w, size):
            noise = int((random.random() - 0.5) * 255 * intensity)
            r, g, b = pixels[x, y][:3]
            a = pixels[x, y][3] if result.mode == 'RGBA' else 255
            nr = max(0, min(255, r + noise))
            ng = max(0, min(255, g + noise))
            nb = max(0, min(255, b + noise))
            for dy in range(size):
                for dx in range(size):
                    if x + dx < w and y + dy < h:
                        if result.mode == 'RGBA':
                            pixels[x + dx, y + dy] = (nr, ng, nb, a)
                        else:
                            pixels[x + dx, y + dy] = (nr, ng, nb)
    return result


def apply_duotone(img: Image.Image, dark: tuple = (20, 0, 40), light: tuple = (255, 200, 100)) -> Image.Image:
    """Map image to two colors based on luminance."""
    gray = img.convert('L')
    result = Image.new('RGBA' if img.mode == 'RGBA' else 'RGB', img.size)
    gray_px = gray.load()
    result_px = result.load()
    w, h = img.size

    for y in range(h):
        for x in range(w):
            t = gray_px[x, y] / 255.0
            r = int(dark[0] * (1 - t) + light[0] * t)
            g = int(dark[1] * (1 - t) + light[1] * t)
            b = int(dark[2] * (1 - t) + light[2] * t)
            if img.mode == 'RGBA':
                a = img.getpixel((x, y))[3]
                result_px[x, y] = (r, g, b, a)
            else:
                result_px[x, y] = (r, g, b)
    return result


def apply_gradient_overlay(
    img: Image.Image,
    color_start: tuple = (0, 0, 0, 200),
    color_end: tuple = (0, 0, 0, 0),
    direction: str = "bottom",
) -> Image.Image:
    """Apply a gradient color overlay."""
    result = img.convert('RGBA')
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    w, h = img.size

    for i in range(h if direction in ("bottom", "top") else w):
        if direction == "bottom":
            t = i / h
        elif direction == "top":
            t = 1 - i / h
        elif direction == "right":
            t = i / w
        else:  # left
            t = 1 - i / w

        r = int(color_start[0] * (1 - t) + color_end[0] * t)
        g = int(color_start[1] * (1 - t) + color_end[1] * t)
        b = int(color_start[2] * (1 - t) + color_end[2] * t)
        a = int(color_start[3] * (1 - t) + color_end[3] * t)

        if direction in ("bottom", "top"):
            draw.line([(0, i), (w, i)], fill=(r, g, b, a))
        else:
            draw.line([(i, 0), (i, h)], fill=(r, g, b, a))

    result = Image.alpha_composite(result, overlay)
    return result


def apply_blur(img: Image.Image, radius: float = 5.0) -> Image.Image:
    """Apply Gaussian blur."""
    return img.filter(ImageFilter.GaussianBlur(radius=radius))


def apply_vignette(img: Image.Image, intensity: float = 0.5, radius: float = 0.8) -> Image.Image:
    """Darken edges with a radial falloff."""
    result = img.convert('RGBA')
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    w, h = img.size
    cx, cy = w / 2, h / 2
    max_dist = math.sqrt(cx ** 2 + cy ** 2)

    for y in range(h):
        for x in range(w):
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2) / max_dist
            alpha = max(0, min(255, int(255 * intensity * max(0, (dist - radius) / (1 - radius)))))
            draw.point((x, y), fill=(0, 0, 0, alpha))

    return Image.alpha_composite(result, overlay)


def apply_color_grade(
    img: Image.Image,
    temperature: float = 0.0,   # -1 cool, +1 warm
    tint: float = 0.0,          # -1 green, +1 magenta
    contrast: float = 1.0,
    saturation: float = 1.0,
    brightness: float = 1.0,
) -> Image.Image:
    """Apply lift/gamma/gain style color grading."""
    result = img.copy()

    if brightness != 1.0:
        result = ImageEnhance.Brightness(result).enhance(brightness)
    if contrast != 1.0:
        result = ImageEnhance.Contrast(result).enhance(contrast)
    if saturation != 1.0:
        result = ImageEnhance.Color(result).enhance(saturation)

    # Temperature/tint shift
    if temperature != 0 or tint != 0:
        pixels = result.load()
        w, h = result.size
        is_rgba = result.mode == 'RGBA'
        for y in range(h):
            for x in range(w):
                px = pixels[x, y]
                r, g, b = px[0], px[1], px[2]
                a = px[3] if is_rgba else 255
                # Warm shifts red up and blue down
                r = max(0, min(255, int(r + temperature * 30)))
                b = max(0, min(255, int(b - temperature * 30)))
                # Tint shifts green
                g = max(0, min(255, int(g - tint * 20)))
                if is_rgba:
                    pixels[x, y] = (r, g, b, a)
                else:
                    pixels[x, y] = (r, g, b)

    return result


def apply_desaturate(img: Image.Image, amount: float = 0.5) -> Image.Image:
    """Partially desaturate. 0 = no change, 1 = fully grayscale."""
    return ImageEnhance.Color(img).enhance(1 - amount)


def apply_overlay(img: Image.Image, color: tuple = (0, 0, 0), opacity: float = 0.3) -> Image.Image:
    """Solid color overlay with opacity."""
    result = img.convert('RGBA')
    overlay = Image.new('RGBA', img.size, (*color, int(opacity * 255)))
    return Image.alpha_composite(result, overlay)


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
            "color_start": (0, 0, 0, 180),
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
            print(f"  Applied {name}({params})")
    return result


# ─── iOS Asset Export ────────────────────────────────────────────────

def export_for_ios(img: Image.Image, output_dir: str, name: str):
    """Export image at 1x, 2x, 3x for iOS asset catalog."""
    os.makedirs(output_dir, exist_ok=True)

    # Determine base size (1x = whatever fits reasonably)
    w, h = img.size
    base_w = min(w, 390)  # iPhone width
    scale_factor = base_w / w
    base_h = int(h * scale_factor)

    scales = {"1x": 1, "2x": 2, "3x": 3}
    filenames = {}

    for label, mult in scales.items():
        sw, sh = int(base_w * mult), int(base_h * mult)
        # Don't upscale beyond original
        if sw > w or sh > h:
            sw, sh = w, h
        resized = img.resize((sw, sh), Image.LANCZOS)
        fname = f"{name}{'@' + label if label != '1x' else ''}.png"
        resized.save(os.path.join(output_dir, fname), "PNG")
        filenames[label] = fname
        print(f"  Exported {fname} ({sw}x{sh})")

    # Write Contents.json
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

def parse_color(s: str) -> tuple:
    """Parse '255,128,0' or '#FF8000' into (r,g,b)."""
    s = s.strip()
    if s.startswith('#'):
        h = s.lstrip('#')
        return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
    parts = [int(x.strip()) for x in s.split(',')]
    return tuple(parts)


def parse_param(val: str):
    """Parse a CLI param value to the right type."""
    if val.lower() in ('true', 'false'):
        return val.lower() == 'true'
    try:
        if '.' in val:
            return float(val)
        return int(val)
    except ValueError:
        # Try as color tuple
        if ',' in val:
            try:
                return tuple(int(x) for x in val.split(','))
            except ValueError:
                pass
        return val


def main():
    parser = argparse.ArgumentParser(description="Drift Image Effects Engine")
    parser.add_argument("input", nargs="?", help="Input image path")
    parser.add_argument("output", nargs="?", help="Output path (file or directory for iOS export)")
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

    # Load image
    img = Image.open(args.input)
    if img.mode not in ('RGB', 'RGBA'):
        img = img.convert('RGBA')
    print(f"Loaded {args.input} ({img.size[0]}x{img.size[1]}, {img.mode})")

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
        # Parse params
        params = {}
        if args.params:
            for p in args.params:
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
    if args.ios_export:
        export_for_ios(result, args.output, args.asset_name)
    else:
        result.save(args.output)
        print(f"Saved to {args.output}")


if __name__ == "__main__":
    main()
