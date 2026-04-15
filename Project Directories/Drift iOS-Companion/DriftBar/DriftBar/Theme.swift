import SwiftUI

// Generated from drift.theme.json — do not edit by hand.
// Regenerate with: drift tokens sync  (Phase 2)
//
// Rule: never use Color(.blue), .padding(17), .font(.system(size: 15))
// directly in views. Always reach through Theme.*, Spacing.*, Typography.*.

enum Theme {

    // MARK: Colors — adapt to light/dark automatically
    enum Colors {
        static let accent          = dynamic(light: 0x3D5996, dark: 0x7AA7FF)
        static let accentSecondary = dynamic(light: 0x8B5CF6, dark: 0xB07AFF)

        static let bg              = dynamic(light: 0xFFFFFF, dark: 0x0B0D10)
        static let bgElevated      = dynamic(light: 0xF7F7F9, dark: 0x14171C)
        static let bgRaised        = dynamic(light: 0xEEF0F4, dark: 0x1B1F26)
        static let border          = dynamic(light: 0xE3E5EA, dark: 0x242932)

        static let text            = dynamic(light: 0x14171C, dark: 0xE7EAF0)
        static let textDim         = dynamic(light: 0x5A6372, dark: 0x8D97A8)
        static let textMuted       = dynamic(light: 0x8D97A8, dark: 0x5A6372)

        static let pass            = dynamic(light: 0x27AE60, dark: 0x3ECF8E)
        static let warn            = dynamic(light: 0xD4930B, dark: 0xF0B429)
        static let fail            = dynamic(light: 0xD4584E, dark: 0xF06262)
    }

    // MARK: Spacing — 4pt grid
    enum Spacing {
        static let s0:  CGFloat = 0
        static let s1:  CGFloat = 4
        static let s2:  CGFloat = 8
        static let s3:  CGFloat = 12
        static let s4:  CGFloat = 16
        static let s5:  CGFloat = 20
        static let s6:  CGFloat = 24
        static let s7:  CGFloat = 32
        static let s8:  CGFloat = 40
        static let s9:  CGFloat = 48
        static let s10: CGFloat = 64
    }

    // MARK: Radius
    enum Radius {
        static let sm:   CGFloat = 4
        static let md:   CGFloat = 8
        static let lg:   CGFloat = 12
        static let xl:   CGFloat = 16
        static let pill: CGFloat = 999
    }

    // MARK: Typography — semantic styles, not raw sizes
    enum Typography {
        static let xs   = Font.system(size: 11, weight: .regular)
        static let sm   = Font.system(size: 12, weight: .regular)
        static let base = Font.system(size: 13, weight: .regular)
        static let md   = Font.system(size: 15, weight: .regular)
        static let lg   = Font.system(size: 17, weight: .medium)
        static let xl   = Font.system(size: 22, weight: .semibold)
        static let xxl  = Font.system(size: 28, weight: .semibold)
        static let xxxl = Font.system(size: 34, weight: .bold)

        static let mono = Font.system(.body, design: .monospaced)
    }

    // MARK: Opacity
    enum Opacity {
        static let disabled: Double = 0.4
        static let muted:    Double = 0.6
        static let overlay:  Double = 0.5
        static let scrim:    Double = 0.55
    }

    // MARK: Motion
    enum Motion {
        static let fast: Double = 0.15
        static let base: Double = 0.25
        static let slow: Double = 0.4

        static let spring = Animation.spring(response: 0.35, dampingFraction: 0.75)
        static let standard = Animation.easeInOut(duration: base)
    }

    // MARK: Shadow modifier
    struct ShadowStyle {
        let x: CGFloat; let y: CGFloat; let blur: CGFloat; let color: Color
        static let sm = ShadowStyle(x: 0, y: 1, blur: 2,  color: .black.opacity(0.08))
        static let md = ShadowStyle(x: 0, y: 4, blur: 12, color: .black.opacity(0.12))
        static let lg = ShadowStyle(x: 0, y: 8, blur: 24, color: .black.opacity(0.25))
    }

    // MARK: - Helpers

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
            return NSColor(hex: isDark ? dark : light)
        }))
        #else
        return Color(uiColor: UIColor { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? dark : light)
        })
        #endif
    }
}

// MARK: - Convenience extensions

extension View {
    func themeShadow(_ style: Theme.ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.blur, x: style.x, y: style.y)
    }
}

#if os(macOS)
private extension NSColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8)  & 0xFF) / 255
        let b = CGFloat( hex        & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
#else
private extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8)  & 0xFF) / 255
        let b = CGFloat( hex        & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
#endif
