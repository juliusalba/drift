# drift-inspire — Design Inspiration from Real Products

## Purpose

Pull design inspiration from real-world apps (via Refero), production-ready component libraries (via 21st.dev), and your own Figma tokens — then synthesize the best patterns into SwiftUI code for your iOS app.

## When to Use

- Starting a new screen and want to see how top apps solve the same problem
- A screen feels "off" but you're not sure what's wrong — compare against real products
- Need a specific component pattern (paywall, onboarding, data table) done well
- Want to upgrade an existing screen with production-quality design patterns

## MCP Dependencies

| MCP | Role | Tool Functions |
|---|---|---|
| **Refero** | Real-world design reference from top apps | `refero_search_screens`, `refero_get_screen`, `refero_search_flows`, `refero_get_flow` |
| **21st.dev (Magic)** | Production-ready component generation | `21st_magic_component_builder`, `21st_magic_component_inspiration` |
| **Figma** | Your project's specific design tokens | Figma MCP (colors, typography, spacing from your file) |

## Workflow

### Step 1 — Analyze the Current Screen

Read the target SwiftUI view file and determine:

1. **Screen type**: What is this? (login, settings, onboarding, dashboard, profile, etc.)
2. **Current patterns**: What UI patterns are already used? (list, cards, tabs, forms)
3. **Visual style**: Dark/light mode, color scheme, typography choices
4. **Pain points**: What feels weak? (empty states, visual hierarchy, spacing, CTA placement)

### Step 2 — Search Refero for Reference Screens

Query Refero with a descriptive search combining screen type, patterns, and style:

```
refero_search_screens:
  query: "onboarding welcome screen with illustration and progress indicator dark mode"
  platform: ios
```

**Search strategy — layer specificity:**

1. **Broad first**: Search the screen type → `"settings page"`
2. **Add patterns**: → `"settings page with toggle switches sections"`
3. **Add style**: → `"settings page dark mode minimal with sections"`
4. **Add company**: → `"settings page linear"` (if you want a specific reference)

Get details on the best matches:

```
refero_get_screen:
  screen_ids: ["uuid1", "uuid2", "uuid3"]
  image_size: thumbnail
  include_similar: true
```

### Step 3 — Search for Flows (Multi-Screen Journeys)

If the screen is part of a flow (onboarding, checkout, auth), search for complete flows:

```
refero_search_flows:
  query: "onboarding with permissions and personalization"
  platform: ios
```

Then get the full flow details:

```
refero_get_flow:
  flow_id: 1234
```

### Step 4 — Get Component Inspiration from 21st.dev

For specific UI components, query 21st.dev Magic:

```
21st_magic_component_inspiration:
  query: "pricing card with annual monthly toggle"
```

Then build a production-ready component:

```
21st_magic_component_builder:
  description: "A pricing card with plan name, price, feature list, and CTA button. Dark theme with subtle border."
```

> **Note**: 21st.dev generates React/web components. Translate the design patterns (layout, spacing, typography hierarchy, color usage) into SwiftUI — don't try to port the code directly.

### Step 5 — Get Your Design Tokens (Figma)

If Figma MCP is connected, fetch your project's design tokens:

- **Colors**: Primary, secondary, accent, background, surface, text colors
- **Typography**: Font families, sizes, weights for each text style
- **Spacing**: Padding/margin scale
- **Corner radii**: Border radius values

These ensure the inspired design uses YOUR brand, not generic colors.

### Step 6 — Synthesize and Generate SwiftUI

Now combine insights from all three sources:

1. **Layout structure** from Refero (how do real apps arrange this screen?)
2. **Component quality** from 21st.dev (production-ready polish and patterns)
3. **Brand tokens** from Figma (your specific colors, fonts, spacing)

Generate SwiftUI code that:
- Uses your project's existing design tokens and color scheme
- Follows the layout patterns seen in the best reference screens
- Applies component-level polish from 21st.dev patterns
- Maintains consistency with your other screens

### Step 7 — Validate with drift-check

After generating/modifying the screen, run `/drift-check` to verify:
- The new screen scores well against any existing Figma design
- Visual consistency with other screens is maintained
- No regressions introduced in other views

## Synthesis Principles

When combining inspiration from multiple sources, follow these rules:

1. **Triangulate patterns**: If 3+ reference apps do something the same way, it's a validated pattern. Use it.
2. **Your tokens win**: Never use a reference app's exact colors/fonts. Always map to your project's design system.
3. **Adapt, don't copy**: Take the layout structure and spacing rhythm, not pixel-exact replication.
4. **iOS-native first**: Prefer native iOS patterns (NavigationStack, List, Form) over custom implementations when they fit.
5. **Accessibility**: Ensure Dynamic Type support, sufficient contrast ratios, and VoiceOver labels.

## Example: Upgrading a Settings Screen

```
1. Analyze: Current SettingsView uses a flat VStack with TextField and Toggle
2. Refero: Search "settings page ios dark mode sections" → find Linear, Spotify patterns
   - Both use grouped sections with headers
   - Toggle rows have icon + label + description
   - Sections have subtle background differentiation
3. 21st.dev: Search "settings form with sections" → get component structure
   - Grouped rows with consistent height
   - Subtle dividers between items
   - Section headers in small caps
4. Figma: Get brand colors → primary blue, dark surface, neutral text hierarchy
5. Generate: SwiftUI Form with .grouped style, custom SettingRow component,
   sections for Account, Preferences, About
6. Validate: Run /drift-check → 94% score
```

## Safety Rules

1. **Visual-only changes**: Never modify business logic, data models, or navigation structure
2. **Preserve functionality**: All existing features must still work after visual upgrades
3. **Git safety**: Every change is a separate commit for easy review/revert
4. **Confidence gating**: Only auto-apply high-confidence patterns. Flag uncertain choices as comments.
