# drift-assets — Stock Photo Sourcing & Visual Asset Pipeline

## Purpose

Find, download, process, and integrate stock photos and visual assets into an iOS project's Xcode asset catalog — with professional image effects applied automatically.

## When to Use

- A screen needs a hero image, background, or placeholder photo
- The design calls for imagery with specific visual treatments (grain, duotone, gradients)
- You want to quickly prototype a screen with real photography instead of colored rectangles
- Building onboarding, marketing, or content-heavy screens that need imagery

## MCP Dependencies

This skill orchestrates multiple tools:

| Tool | Purpose |
|---|---|
| **Refero MCP** | See how top apps use imagery on similar screens (placement, sizing, effects) |
| **WebSearch** | Find stock photos from Unsplash, Pexels, and other free sources |
| **WebFetch** | Download images from URLs |
| **Python/PIL** | Apply effects (grain, duotone, gradient, blur, vignette, color grading) |

## Workflow

### Step 1 — Analyze the Screen

Read the target SwiftUI view file. Determine:
- What type of screen is this? (onboarding, profile, settings, etc.)
- What imagery would enhance it? (hero photo, background texture, avatar placeholder)
- What's the visual style? (dark/light, editorial, vibrant, moody)

### Step 2 — Get Design Reference from Refero

Use `refero_search_screens` to find how top apps handle imagery for this screen type:

```
Query: "onboarding screen with hero image dark mode"
Platform: ios
```

Examine the results to understand:
- Image placement (full-bleed, card, circular crop)
- Effect treatments (do they use overlays? gradients? grain?)
- Aspect ratios and sizing

### Step 3 — Source Stock Photos

Use **WebSearch** to find free stock photos:

```
Search: "site:unsplash.com warm lifestyle morning coffee"
```

Or use the stock_photos.py script directly:

```bash
python3 scripts/stock_photos.py search "warm lifestyle morning" --orientation portrait --count 5
```

Then download with WebFetch or the script:

```bash
python3 scripts/stock_photos.py download "<url>" --output /tmp/drift_hero.jpg
```

### Step 4 — Apply Effects

Use the image effects engine. Available presets:

| Preset | Effects | Best For |
|---|---|---|
| `editorial` | desaturate(0.3) → grain(0.12) → vignette(0.4) | Blog, magazine style |
| `vibrant` | warm color grade → grain(0.06) | Lifestyle, social |
| `moody` | duotone(dark purple/gold) → vignette → grain | Dark UI, premium |
| `minimal` | desaturate(0.6) → blur → soft contrast | Backgrounds, subtle |
| `hero` | bottom gradient fade → vignette | Hero images with text overlay |
| `dark_ui` | dark overlay → desaturate → grain | Dark mode backgrounds |
| `warm_glow` | warm temp → vignette → grain | Cozy, lifestyle |
| `cool_tone` | cool temp → desaturate → grain | Tech, professional |

```bash
python3 scripts/image_effects.py input.jpg output.png --preset moody
```

Or apply individual effects:

```bash
python3 scripts/image_effects.py input.jpg output.png \
  --effect grain --params intensity=0.15 \
  --effect vignette --params intensity=0.4
```

### Step 5 — Export to Xcode Asset Catalog

```bash
python3 scripts/stock_photos.py export processed.png \
  --xcassets /path/to/App/Assets.xcassets \
  --name onboarding_hero \
  --preset hero
```

This creates:
```
Assets.xcassets/onboarding_hero.imageset/
├── onboarding_hero.png      (1x)
├── onboarding_hero@2x.png   (2x)
├── onboarding_hero@3x.png   (3x)
└── Contents.json
```

### Step 6 — Wire Into SwiftUI

Add the image reference to the target view:

```swift
Image("onboarding_hero")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(height: 300)
    .clipped()
    .overlay(
        LinearGradient(
            colors: [.clear, .black.opacity(0.6)],
            startPoint: .center,
            endPoint: .bottom
        )
    )
```

## Full Pipeline (Single Command)

```bash
python3 scripts/stock_photos.py pipeline "warm lifestyle morning" \
  --xcassets /path/to/Assets.xcassets \
  --name hero_onboarding \
  --preset moody \
  --orientation portrait
```

## Safety Rules

1. **Only use free-licensed photos** — Unsplash and Pexels licenses allow commercial use
2. **Never modify existing assets** — Always create new imagesets
3. **Preserve originals** — Keep unprocessed downloads in drift-reports/assets/
4. **Git-track assets** — Ensure generated images are committed
5. **Reasonable sizes** — Don't add images over 5MB; resize to appropriate dimensions
