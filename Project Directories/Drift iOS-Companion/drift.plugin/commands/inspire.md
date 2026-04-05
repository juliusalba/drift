# /drift-inspire — Design Inspiration from Real Products

Pull design inspiration from Refero (real app screenshots), 21st.dev (production components), and your Figma tokens to upgrade a screen's visual design.

## Usage

```
/drift-inspire [ScreenName] [--style moody|minimal|vibrant] [--reference app_name]
```

## What It Does

1. **Reads** the target SwiftUI view (or asks which screen to work on)
2. **Searches Refero** for how top apps design the same screen type
3. **Gets component patterns** from 21st.dev Magic for specific UI elements
4. **Fetches your Figma tokens** (if Figma MCP is connected) for brand consistency
5. **Synthesizes** the best patterns into SwiftUI code using your design system
6. **Validates** the result with a drift-check pass

## Examples

```
/drift-inspire SettingsView
/drift-inspire OnboardingView --style moody
/drift-inspire LoginView --reference linear
/drift-inspire                    # Asks which screen to work on
```

## Required MCPs

- **Refero MCP** — for real-world screen references (required)
- **Figma MCP** — for your design tokens (optional, recommended)
- **21st.dev Magic** — for component inspiration (optional)

## Skill Reference

See `skills/drift-inspire/SKILL.md` for the full workflow and pattern reference.
