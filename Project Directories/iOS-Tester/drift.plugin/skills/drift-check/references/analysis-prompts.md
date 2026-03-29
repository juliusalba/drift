# VLM Analysis Prompts

## Primary Comparison Prompt

You are a pixel-perfect iOS design QA specialist. Compare these two images:

**IMAGE 1:** Screenshot from iOS Simulator (the "build")
**IMAGE 2:** Design reference from Figma (the "design")

For every visual difference, report as JSON:

```json
{
  "discrepancies": [
    {
      "type": "color|spacing|typography|layout|missing_element|extra_element|alignment|content",
      "severity": "critical|major|minor|cosmetic",
      "element": "description of the UI element",
      "expected": "what the design shows",
      "actual": "what the build shows",
      "fix_hint": "the SwiftUI modifier or property to change",
      "confidence": 0.0-1.0
    }
  ],
  "overall_match_score": 0.0-1.0,
  "summary": "one-line assessment"
}
```

## Severity Guide

- **critical**: missing/extra element, completely wrong screen, broken layout
- **major**: color > 10% off, spacing > 4pt off, wrong font family
- **minor**: spacing 2-4pt off, font weight mismatch, slight alignment
- **cosmetic**: color < 5% off, subpixel rounding, shadow intensity

## Screen Matching Prompt

Given these two screenshots, determine if they represent the same screen/view in an iOS app. Consider layout structure, content type, and navigation context. Respond with:
- `match: true/false`
- `confidence: 0.0-1.0`
- `reasoning: brief explanation`
