import Foundation

// MARK: - Violation model

struct Violation: Identifiable, Hashable {
    enum Severity: String { case error, warn, info }
    enum Kind: String {
        case hardcodedColor     = "hardcoded-color"
        case magicSpacing       = "magic-spacing"
        case magicRadius        = "magic-radius"
        case rawFontSize        = "raw-font-size"
        case magicOpacity       = "magic-opacity"
        case hexLiteral         = "hex-literal"

        var label: String {
            switch self {
            case .hardcodedColor: "Hardcoded color"
            case .magicSpacing:   "Magic spacing"
            case .magicRadius:    "Magic corner radius"
            case .rawFontSize:    "Raw font size"
            case .magicOpacity:   "Magic opacity"
            case .hexLiteral:     "Hex literal"
            }
        }
    }

    let id = UUID()
    let file: URL
    let line: Int
    let column: Int
    let snippet: String
    let kind: Kind
    let severity: Severity
    let suggestion: String

    var fileName: String { file.lastPathComponent }
}

// MARK: - Engine

final class AuditEngine {
    struct Report {
        let violations: [Violation]
        let scannedFiles: Int
        let elapsed: TimeInterval
        var count: Int { violations.count }
        var byFile: [String: [Violation]] {
            Dictionary(grouping: violations, by: \.fileName)
        }
        var byKind: [Violation.Kind: [Violation]] {
            Dictionary(grouping: violations, by: \.kind)
        }
    }

    /// Files we never audit — Theme.swift defines the tokens, generated code is out of scope.
    private let excludedFileNames: Set<String> = ["Theme.swift"]

    /// Directory segments that short-circuit enumeration (vendored deps, build artefacts, etc.)
    private let excludedDirSegments: Set<String> = [
        "Pods", "Carthage", ".build", "DerivedData", "vendor", "node_modules",
        ".drift-cache", "drift-reports", ".git", ".swiftpm",
        "Tests", "UITests", "DriftBarTests", ".xcodeproj"
    ]

    /// Allowed numeric literals per kind — these map to valid Theme tokens.
    private let allowedSpacing: Set<Int>  = [0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64]
    private let allowedRadius:  Set<Int>  = [0, 4, 8, 12, 16, 999]
    private let allowedFontSize: Set<Int> = [11, 12, 13, 15, 17, 22, 28, 34]

    private let namedColors = [
        "blue", "purple", "red", "green", "yellow", "orange",
        "pink", "indigo", "mint", "teal", "cyan", "brown"
    ]

    func scan(directory: URL) -> Report {
        let start = Date()
        let files = swiftFiles(in: directory)
        var all: [Violation] = []
        for file in files {
            if excludedFileNames.contains(file.lastPathComponent) { continue }
            if let src = try? String(contentsOf: file, encoding: .utf8) {
                all.append(contentsOf: scanSource(src, file: file))
            }
        }
        return Report(
            violations: all.sorted { ($0.fileName, $0.line) < ($1.fileName, $1.line) },
            scannedFiles: files.count,
            elapsed: Date().timeIntervalSince(start)
        )
    }

    // MARK: Pattern detection (per-line; sufficient for v1)

    private func scanSource(_ source: String, file: URL) -> [Violation] {
        var out: [Violation] = []
        let lines = source.components(separatedBy: .newlines)
        for (idx, line) in lines.enumerated() {
            let lineNum = idx + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//") { continue }

            out.append(contentsOf: detectNamedColors(line, file: file, lineNum: lineNum))
            out.append(contentsOf: detectHex(line, file: file, lineNum: lineNum))
            out.append(contentsOf: detectSpacing(line, file: file, lineNum: lineNum))
            out.append(contentsOf: detectRadius(line, file: file, lineNum: lineNum))
            out.append(contentsOf: detectFontSize(line, file: file, lineNum: lineNum))
            out.append(contentsOf: detectOpacity(line, file: file, lineNum: lineNum))
        }
        return out
    }

    private func detectNamedColors(_ line: String, file: URL, lineNum: Int) -> [Violation] {
        var out: [Violation] = []
        for name in namedColors {
            let patterns = [
                #"Color\.\#(name)\b"#,
                #"\.foregroundStyle\(\.\#(name)\b"#,
                #"\.foregroundColor\(\.\#(name)\b"#,
                #"\.fill\(\.\#(name)\b"#,
                #"\.background\(\.\#(name)\b"#,
                #"\.tint\(\.\#(name)\b"#
            ]
            for p in patterns {
                if let range = line.range(of: p, options: .regularExpression) {
                    out.append(Violation(
                        file: file, line: lineNum,
                        column: line.distance(from: line.startIndex, to: range.lowerBound) + 1,
                        snippet: String(line[range]),
                        kind: .hardcodedColor, severity: .error,
                        suggestion: "Use Theme.Colors.\(mapColor(name))"
                    ))
                }
            }
        }
        return out
    }

    private func detectHex(_ line: String, file: URL, lineNum: Int) -> [Violation] {
        guard let range = line.range(of: #"#[0-9a-fA-F]{6}\b"#, options: .regularExpression) else { return [] }
        // Ignore hex inside comments or string literals that are URLs
        return [Violation(
            file: file, line: lineNum,
            column: line.distance(from: line.startIndex, to: range.lowerBound) + 1,
            snippet: String(line[range]),
            kind: .hexLiteral, severity: .warn,
            suggestion: "Move to drift.theme.json then reference Theme.Colors.*"
        )]
    }

    private func detectSpacing(_ line: String, file: URL, lineNum: Int) -> [Violation] {
        return numericMatches(
            in: line,
            patterns: [
                #"\.padding\(\s*(\d+(?:\.\d+)?)\s*\)"#,
                #"\.padding\(\.\w+,\s*(\d+(?:\.\d+)?)\s*\)"#
            ]
        ) { n in
            guard !allowedSpacing.contains(Int(n)) else { return nil }
            return (.magicSpacing, .warn, "Use Theme.Spacing.s\(nearestSpacingTier(n))")
        }.map { Violation(file: file, line: lineNum, column: $0.col, snippet: $0.snippet, kind: $0.kind, severity: $0.severity, suggestion: $0.suggestion) }
    }

    private func detectRadius(_ line: String, file: URL, lineNum: Int) -> [Violation] {
        return numericMatches(
            in: line,
            patterns: [ #"\.cornerRadius\(\s*(\d+(?:\.\d+)?)\s*\)"# ]
        ) { n in
            guard !allowedRadius.contains(Int(n)) else { return nil }
            return (.magicRadius, .warn, "Use Theme.Radius.\(nearestRadius(n))")
        }.map { Violation(file: file, line: lineNum, column: $0.col, snippet: $0.snippet, kind: $0.kind, severity: $0.severity, suggestion: $0.suggestion) }
    }

    private func detectFontSize(_ line: String, file: URL, lineNum: Int) -> [Violation] {
        return numericMatches(
            in: line,
            patterns: [ #"Font\.system\(size:\s*(\d+(?:\.\d+)?)"#, #"\.font\(\.system\(size:\s*(\d+(?:\.\d+)?)"# ]
        ) { n in
            guard !allowedFontSize.contains(Int(n)) else { return nil }
            return (.rawFontSize, .warn, "Use Theme.Typography.\(nearestTypographyTier(n))")
        }.map { Violation(file: file, line: lineNum, column: $0.col, snippet: $0.snippet, kind: $0.kind, severity: $0.severity, suggestion: $0.suggestion) }
    }

    private func detectOpacity(_ line: String, file: URL, lineNum: Int) -> [Violation] {
        // .opacity(0.37) is magic; .opacity(Theme.Opacity.muted) is fine
        let p = #"\.opacity\(\s*(0?\.\d+)\s*\)"#
        guard let m = line.range(of: p, options: .regularExpression) else { return [] }
        return [Violation(
            file: file, line: lineNum,
            column: line.distance(from: line.startIndex, to: m.lowerBound) + 1,
            snippet: String(line[m]),
            kind: .magicOpacity, severity: .info,
            suggestion: "Consider Theme.Opacity.* (disabled / muted / overlay / scrim)"
        )]
    }

    // MARK: Helpers

    private struct NumericMatch {
        let col: Int; let snippet: String
        let kind: Violation.Kind; let severity: Violation.Severity; let suggestion: String
    }

    private func numericMatches(
        in line: String,
        patterns: [String],
        classify: (Double) -> (kind: Violation.Kind, severity: Violation.Severity, suggestion: String)?
    ) -> [NumericMatch] {
        var out: [NumericMatch] = []
        for p in patterns {
            guard let regex = try? NSRegularExpression(pattern: p) else { continue }
            let ns = line as NSString
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: ns.length))
            for m in matches where m.numberOfRanges >= 2 {
                let numStr = ns.substring(with: m.range(at: 1))
                guard let n = Double(numStr) else { continue }
                guard let c = classify(n) else { continue }
                let full = ns.substring(with: m.range)
                out.append(NumericMatch(
                    col: m.range.location + 1, snippet: full,
                    kind: c.kind, severity: c.severity, suggestion: c.suggestion
                ))
            }
        }
        return out
    }

    private func mapColor(_ name: String) -> String {
        switch name {
        case "blue", "purple", "indigo": "accent"
        case "green", "mint", "teal":    "pass"
        case "yellow", "orange":         "warn"
        case "red", "pink":              "fail"
        default:                         "accent"
        }
    }

    private func nearestSpacingTier(_ n: Double) -> Int {
        let tiers: [(Int, Double)] = [(0,0),(1,4),(2,8),(3,12),(4,16),(5,20),(6,24),(7,32),(8,40),(9,48),(10,64)]
        return tiers.min { abs($0.1 - n) < abs($1.1 - n) }!.0
    }

    private func nearestRadius(_ n: Double) -> String {
        if n < 3 { return "sm" }
        if n < 10 { return "md" }
        if n < 14 { return "lg" }
        if n < 100 { return "xl" }
        return "pill"
    }

    private func nearestTypographyTier(_ n: Double) -> String {
        switch n {
        case ..<12:  "xs"
        case ..<13:  "sm"
        case ..<15:  "base"
        case ..<17:  "md"
        case ..<22:  "lg"
        case ..<28:  "xl"
        case ..<34:  "xxl"
        default:     "xxxl"
        }
    }

    private func swiftFiles(in dir: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }
        var out: [URL] = []
        for case let url as URL in enumerator {
            // Skip entire excluded dirs (don't descend into them).
            if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
               excludedDirSegments.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }
            if url.pathExtension == "swift" { out.append(url) }
        }
        return out
    }
}
