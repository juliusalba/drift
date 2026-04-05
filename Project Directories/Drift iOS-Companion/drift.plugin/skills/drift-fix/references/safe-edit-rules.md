# Safe Edit Rules

## ALLOWED Edits (visual-only)
- Colors: foregroundColor, background, tint, accentColor
- Spacing: padding, spacing in Stacks, Spacer frame
- Typography: font, fontWeight, lineSpacing, kerning
- Layout: frame, alignment, position within stacks
- Shape: cornerRadius, clipShape, overlay borders
- Shadow: shadow modifier
- Opacity: opacity modifier
- Sizing: frame width/height, minWidth, maxWidth

## NEVER Edit
- State variables (@State, @Binding, @ObservedObject, @StateObject, @EnvironmentObject)
- Data flow (function calls, API requests, network layer)
- Navigation logic (NavigationLink destinations, router logic)
- Business logic (calculations, validations, transformations)
- Conditional rendering logic (unless purely visual)
- Third-party SDK calls
- Info.plist or project configuration

## Escalation Rules
- Fix requires > 20 lines changed -> FLAG for human review
- Confidence < 0.7 -> Add `// DRIFT: Suggested fix` comment only
- Critical severity -> NEVER auto-fix, always flag
- Affects multiple screens -> Fix in shared component if identifiable, otherwise fix individually
- File has merge conflicts -> STOP, flag for human
