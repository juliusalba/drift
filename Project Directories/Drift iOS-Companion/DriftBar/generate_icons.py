"""
Generate DriftBar app icons and menu bar template icons.

Design concept: Two overlapping rounded squares, slightly offset —
representing the "drift" between a design and a build.
The front square has a checkmark, suggesting compliance checking.
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

BASE = os.path.dirname(os.path.abspath(__file__))
ICON_DIR = os.path.join(BASE, "DriftBar", "Assets.xcassets", "AppIcon.appiconset")
MENUBAR_DIR = os.path.join(BASE, "DriftBar", "Assets.xcassets", "MenuBarIcon.imageset")

os.makedirs(ICON_DIR, exist_ok=True)
os.makedirs(MENUBAR_DIR, exist_ok=True)


def draw_app_icon(size: int) -> Image.Image:
    """Draw the Drift app icon at the given size."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background: dark rounded rect
    pad = int(size * 0.04)
    corner = int(size * 0.22)
    draw.rounded_rectangle(
        [pad, pad, size - pad, size - pad],
        radius=corner,
        fill=(17, 17, 17, 255),
    )

    # Back square (design reference) — blue, offset up-left
    sq_size = int(size * 0.36)
    cx, cy = size // 2, size // 2
    offset = int(size * 0.06)
    back_x = cx - offset - sq_size // 2
    back_y = cy - offset - sq_size // 2
    sq_corner = int(size * 0.06)
    draw.rounded_rectangle(
        [back_x, back_y, back_x + sq_size, back_y + sq_size],
        radius=sq_corner,
        fill=(59, 130, 246, 180),  # blue, slightly transparent
    )

    # Front square (build) — white/bright
    front_x = cx + offset - sq_size // 2
    front_y = cy + offset - sq_size // 2
    draw.rounded_rectangle(
        [front_x, front_y, front_x + sq_size, front_y + sq_size],
        radius=sq_corner,
        fill=(255, 255, 255, 240),
    )

    # Checkmark inside front square
    check_cx = front_x + sq_size // 2
    check_cy = front_y + sq_size // 2
    cs = int(sq_size * 0.30)  # checkmark scale
    lw = max(2, int(size * 0.025))

    # Checkmark points
    p1 = (check_cx - cs, check_cy)
    p2 = (check_cx - cs // 3, check_cy + cs * 2 // 3)
    p3 = (check_cx + cs, check_cy - cs * 2 // 3)

    draw.line([p1, p2, p3], fill=(17, 17, 17, 255), width=lw, joint="curve")

    # Connecting lines (drift arrows) — subtle
    # Small diagonal dashes between the two squares
    dash_color = (59, 130, 246, 100)
    dash_w = max(1, int(size * 0.012))

    for i in range(3):
        t = 0.3 + i * 0.2
        dx = int(back_x + sq_size + (front_x - back_x - sq_size) * t)
        dy = int(back_y + sq_size + (front_y - back_y - sq_size) * t)
        dl = int(size * 0.03)
        draw.line(
            [(dx - dl, dy - dl), (dx + dl, dy + dl)],
            fill=dash_color,
            width=dash_w,
        )

    return img


def draw_menubar_icon(size: int) -> Image.Image:
    """Draw the menu bar template icon (monochrome, black on transparent)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Two overlapping squares, simplified for small size
    sq = int(size * 0.4)
    offset = int(size * 0.12)
    cx, cy = size // 2, size // 2
    corner = max(1, int(size * 0.08))
    lw = max(1, int(size * 0.08))

    # Back square — outline only
    bx = cx - offset - sq // 2
    by = cy - offset - sq // 2
    draw.rounded_rectangle(
        [bx, by, bx + sq, by + sq],
        radius=corner,
        outline=(0, 0, 0, 180),
        width=lw,
    )

    # Front square — filled
    fx = cx + offset - sq // 2
    fy = cy + offset - sq // 2
    draw.rounded_rectangle(
        [fx, fy, fx + sq, fy + sq],
        radius=corner,
        fill=(0, 0, 0, 220),
    )

    # Checkmark in front square
    ccx = fx + sq // 2
    ccy = fy + sq // 2
    cs = int(sq * 0.25)
    clw = max(1, int(size * 0.06))

    p1 = (ccx - cs, ccy)
    p2 = (ccx - cs // 3, ccy + cs * 2 // 3)
    p3 = (ccx + cs, ccy - cs * 2 // 3)
    draw.line([p1, p2, p3], fill=(255, 255, 255, 255), width=clw, joint="curve")

    return img


# --- Generate App Icons ---
app_icon_sizes = [16, 32, 64, 128, 256, 512, 1024]
filenames = []

for s in app_icon_sizes:
    icon = draw_app_icon(s)
    fname = f"icon_{s}x{s}.png"
    icon.save(os.path.join(ICON_DIR, fname))
    filenames.append((s, fname))
    print(f"  Generated {fname}")

# Write Contents.json for AppIcon
import json

images = []
size_map = {
    16: [("1x", 16), ("2x", 32)],
    32: [("1x", 32), ("2x", 64)],
    128: [("1x", 128), ("2x", 256)],
    256: [("1x", 256), ("2x", 512)],
    512: [("1x", 512), ("2x", 1024)],
}

for base_size, scales in size_map.items():
    for scale_label, actual_size in scales:
        images.append({
            "filename": f"icon_{actual_size}x{actual_size}.png",
            "idiom": "mac",
            "scale": scale_label,
            "size": f"{base_size}x{base_size}",
        })

contents = {"images": images, "info": {"author": "xcode", "version": 1}}
with open(os.path.join(ICON_DIR, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)
print("  Updated AppIcon Contents.json")


# --- Generate Menu Bar Icons ---
for size, suffix in [(18, ""), (36, "@2x"), (54, "@3x")]:
    icon = draw_menubar_icon(size)
    fname = f"menubar{suffix}.png"
    icon.save(os.path.join(MENUBAR_DIR, fname))
    print(f"  Generated {fname}")

menubar_contents = {
    "images": [
        {"filename": "menubar.png", "idiom": "universal", "scale": "1x"},
        {"filename": "menubar@2x.png", "idiom": "universal", "scale": "2x"},
        {"filename": "menubar@3x.png", "idiom": "universal", "scale": "3x"},
    ],
    "info": {"author": "xcode", "version": 1},
    "properties": {"template-rendering-intent": "template"},
}
with open(os.path.join(MENUBAR_DIR, "Contents.json"), "w") as f:
    json.dump(menubar_contents, f, indent=2)
print("  Updated MenuBarIcon Contents.json")

print("\nDone! All icons generated.")
