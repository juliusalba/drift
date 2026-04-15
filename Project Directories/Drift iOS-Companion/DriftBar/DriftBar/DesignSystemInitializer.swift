import Foundation

/// Writes the canonical `drift.theme.json` + `Theme.swift` into a target project so
/// the audit + fixer loop has something to enforce against.
enum DesignSystemInitializer {

    struct Result {
        let themeJSON: URL
        let themeSwift: URL
        let swiftWasNew: Bool
        let jsonWasNew: Bool
    }

    enum Failure: Error, LocalizedError {
        case noWritableDirectory
        var errorDescription: String? {
            "Couldn't find a writable directory to drop Theme.swift into."
        }
    }

    /// Drops both files. `drift.theme.json` at the project root, `Theme.swift` in the
    /// most likely main-source directory (heuristic: first non-Pods/build dir with >0 .swift files).
    static func initialize(in projectDir: URL) throws -> Result {
        let jsonURL = projectDir.appendingPathComponent("drift.theme.json")
        let jsonIsNew = !FileManager.default.fileExists(atPath: jsonURL.path)
        if jsonIsNew {
            try themeJSON.write(to: jsonURL, atomically: true, encoding: .utf8)
        }

        let sourceDir = bestSourceDirectory(in: projectDir) ?? projectDir
        let swiftURL = sourceDir.appendingPathComponent("Theme.swift")
        let swiftIsNew = !FileManager.default.fileExists(atPath: swiftURL.path)
        if swiftIsNew {
            try themeSwift.write(to: swiftURL, atomically: true, encoding: .utf8)
        }

        return Result(themeJSON: jsonURL, themeSwift: swiftURL, swiftWasNew: swiftIsNew, jsonWasNew: jsonIsNew)
    }

    /// Returns true if the target project already has a Theme.swift referencing the token enum.
    static func isInitialized(in projectDir: URL) -> Bool {
        guard let en = FileManager.default.enumerator(
            at: projectDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return false }
        for case let url as URL in en where url.lastPathComponent == "Theme.swift" {
            if let body = try? String(contentsOf: url, encoding: .utf8),
               body.contains("enum Theme") && body.contains("Theme.Colors") {
                return true
            }
        }
        return false
    }

    // MARK: - Heuristic: find "main" source directory

    private static let skippedDirs: Set<String> = [
        "Pods", "Carthage", ".build", "DerivedData", "vendor", "node_modules",
        ".drift-cache", "drift-reports", ".git", ".swiftpm", "Tests", "UITests"
    ]

    private static func bestSourceDirectory(in projectDir: URL) -> URL? {
        // Prefer a direct subdir that matches the project name; else the one with the most .swift files.
        let projectName = projectDir.lastPathComponent
        let items = (try? FileManager.default.contentsOfDirectory(
            at: projectDir,
            includingPropertiesForKeys: [.isDirectoryKey]
        )) ?? []
        let dirs = items.filter {
            (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            && !skippedDirs.contains($0.lastPathComponent)
            && !$0.lastPathComponent.hasSuffix(".xcodeproj")
            && !$0.lastPathComponent.hasSuffix(".xcworkspace")
        }
        if let preferred = dirs.first(where: { $0.lastPathComponent == projectName }) {
            return preferred
        }
        return dirs
            .map { ($0, swiftCount(in: $0)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .first?.0
    }

    private static func swiftCount(in dir: URL) -> Int {
        guard let en = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return 0 }
        var n = 0
        for case let url as URL in en where url.pathExtension == "swift" { n += 1 }
        return n
    }

    // MARK: - Templates

    private static let themeJSON: String = #"""
    {
      "$schema": "https://drift.dev/schema/theme-v1.json",
      "name": "Project",
      "version": 1,
      "color": {
        "accent":          { "light": "#3D5996", "dark": "#7AA7FF" },
        "accentSecondary": { "light": "#8B5CF6", "dark": "#B07AFF" },
        "bg":              { "light": "#FFFFFF", "dark": "#0B0D10" },
        "bgElevated":      { "light": "#F7F7F9", "dark": "#14171C" },
        "bgRaised":        { "light": "#EEF0F4", "dark": "#1B1F26" },
        "border":          { "light": "#E3E5EA", "dark": "#242932" },
        "text":            { "light": "#14171C", "dark": "#E7EAF0" },
        "textDim":         { "light": "#5A6372", "dark": "#8D97A8" },
        "textMuted":       { "light": "#8D97A8", "dark": "#5A6372" },
        "pass":            { "light": "#27AE60", "dark": "#3ECF8E" },
        "warn":            { "light": "#D4930B", "dark": "#F0B429" },
        "fail":            { "light": "#D4584E", "dark": "#F06262" }
      },
      "spacing": { "unit": 4, "0": 0, "1": 4, "2": 8, "3": 12, "4": 16, "5": 20, "6": 24, "7": 32, "8": 40, "9": 48, "10": 64 },
      "radius":  { "none": 0, "sm": 4, "md": 8, "lg": 12, "xl": 16, "pill": 999 }
    }
    """#

    private static let themeSwift: String = #"""
    import SwiftUI

    // Generated by Drift. Regenerate via the Audit window.
    // Rule: never use Color.blue, .padding(17), .font(.system(size: 15)) in views.
    // Always reach through Theme.*, never raw values.

    enum Theme {
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

        enum Spacing {
            static let s0: CGFloat = 0,  s1: CGFloat = 4,  s2: CGFloat = 8
            static let s3: CGFloat = 12, s4: CGFloat = 16, s5: CGFloat = 20
            static let s6: CGFloat = 24, s7: CGFloat = 32, s8: CGFloat = 40
            static let s9: CGFloat = 48, s10: CGFloat = 64
        }

        enum Radius {
            static let sm:   CGFloat = 4,  md: CGFloat = 8, lg: CGFloat = 12
            static let xl:   CGFloat = 16, pill: CGFloat = 999
        }

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

        enum Opacity {
            static let disabled: Double = 0.4, muted: Double = 0.6
            static let overlay:  Double = 0.5, scrim: Double = 0.55
        }

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
    """#
}
