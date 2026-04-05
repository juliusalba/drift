# /drift-assets — Stock Photos & Visual Asset Pipeline

Find stock photos, apply professional image effects, and export directly to your Xcode asset catalog.

## Usage

```
/drift-assets [description] [--preset name] [--screen ScreenName]
```

## What It Does

1. **Analyzes** the target screen to determine what imagery is needed
2. **Searches Refero** to see how similar apps use photography
3. **Finds stock photos** from free sources (Unsplash, Pexels) via web search
4. **Applies effects** — grain, duotone, gradient, blur, vignette, color grading
5. **Exports to Xcode** — creates properly scaled 1x/2x/3x imageset in Assets.xcassets
6. **Wires into SwiftUI** — adds the Image() reference to your view code

## Effect Presets

| Preset | Look | Best For |
|---|---|---|
| `editorial` | Slightly desaturated + grain + vignette | Blog, magazine |
| `vibrant` | Warm tones + subtle grain | Lifestyle, social |
| `moody` | Duotone purple/gold + heavy grain | Dark UI, premium |
| `minimal` | Desaturated + soft blur | Backgrounds |
| `hero` | Bottom gradient fade + vignette | Hero images with text |
| `dark_ui` | Dark overlay + desaturate + grain | Dark mode backgrounds |
| `warm_glow` | Warm color grade + vignette | Cozy, lifestyle |
| `cool_tone` | Cool blue shift + grain | Tech, professional |

## Examples

```
/drift-assets "warm lifestyle photo for onboarding" --preset hero
/drift-assets "abstract gradient background" --preset dark_ui --screen HomeView
/drift-assets "coffee shop morning light" --preset editorial
/drift-assets                    # Analyzes current screen and suggests
```

## Individual Effects

You can also request specific effects instead of presets:

- `grain` — Film grain texture (intensity: 0-1)
- `duotone` — Two-color tonal mapping (dark/light color pair)
- `gradient_overlay` — Color gradient overlay (direction: top/bottom/left/right)
- `blur` — Gaussian blur (radius in pixels)
- `vignette` — Darkened edges (intensity: 0-1)
- `color_grade` — Temperature, tint, contrast, saturation, brightness
- `desaturate` — Partial grayscale (amount: 0-1)
- `overlay` — Solid color overlay (color + opacity)

## Required Tools

- **WebSearch + WebFetch** — for finding and downloading stock photos
- **Python 3 + Pillow** — for image processing (`pip3 install Pillow`)
- **Refero MCP** — for imagery reference (optional)

## Skill Reference

See `skills/drift-assets/SKILL.md` for the full workflow.
Scripts: `skills/drift-assets/scripts/image_effects.py`, `skills/drift-assets/scripts/stock_photos.py`
