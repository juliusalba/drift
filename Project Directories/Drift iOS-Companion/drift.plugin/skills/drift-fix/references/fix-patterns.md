# Fix Pattern Library

## Color Mismatch
```swift
// Change foreground color
.foregroundColor(Color(hex: "CORRECT_HEX"))

// Change background
.background(Color(hex: "CORRECT_HEX"))

// Update theme token (preferred if project uses a theme)
.foregroundColor(Color.theme.primaryText)
```

## Spacing Off
```swift
// Adjust padding
.padding(.horizontal, CORRECT_VALUE)
.padding(.vertical, CORRECT_VALUE)
.padding(.top, CORRECT_VALUE)

// Adjust stack spacing
VStack(spacing: CORRECT_VALUE) { ... }
HStack(spacing: CORRECT_VALUE) { ... }
```

## Font Wrong
```swift
// System font
.font(.system(size: SIZE, weight: .WEIGHT))

// Custom font
.font(.custom("FontName", size: SIZE))

// Design system font (preferred)
.font(.theme.heading1)
```

## Corner Radius
```swift
.clipShape(RoundedRectangle(cornerRadius: VALUE))
// or
.cornerRadius(VALUE)  // deprecated but common
```

## Missing Element
Insert the missing SwiftUI view at the correct position in the view hierarchy. Match the design's visual appearance.

## Extra Element
Remove the element or hide it:
```swift
// If safe to remove, delete the view code
// If unsure, hide it:
.hidden()
```

## Alignment
```swift
VStack(alignment: .leading) { ... }
HStack(alignment: .top) { ... }
.frame(maxWidth: .infinity, alignment: .leading)
```

## Layout Order
Reorder children within VStack/HStack/ZStack to match the design's visual order.
