import SwiftUI
import AppKit

/// A/B comparison with annotated screenshot, visual diff guides, and one-click fixes.
struct ComparisonView: View {
    let screen: DriftScreen
    let image: NSImage?
    let service: DriftService?
    @State private var selectedIssue: Int? = nil
    @State private var copiedIndex: Int? = nil
    @State private var showSaved = false
    @State private var sliderPosition: CGFloat = 0.5 // A/B slider: 0=current, 1=expected

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().opacity(0.5)

            HSplitView {
                // Left: A/B image comparison
                imagePanel
                    .frame(minWidth: 300)

                // Right: Issue cards
                issuePanel
                    .frame(width: 290)
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            // Screen info
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(screen.name)
                        .font(.system(size: 14, weight: .semibold))
                    Text(screen.filePath)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: statusSymbol)
                            .font(.system(size: 9))
                        Text(screen.score.scoreFormatted)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(scoreColor)

                    let open = screen.discrepancies.filter { $0.status == .open }.count
                    let fixed = screen.discrepancies.filter { $0.status == .fixed }.count
                    if open > 0 {
                        Text("\(open) open")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                    if fixed > 0 {
                        Text("\(fixed) fixed")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            // Fix All
            let openCount = screen.discrepancies.filter { $0.status == .open }.count
            if openCount > 0 {
                Button {
                    service?.fixAllWithClaude(screen: screen)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 10))
                        Text("Fix All (\(openCount))")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Export
            Button {
                saveReport()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: showSaved ? "checkmark" : "arrow.down.doc")
                        .font(.system(size: 10))
                    Text(showSaved ? "Saved" : "Export")
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(showSaved ? Color.green.opacity(0.1) : Color.primary.opacity(0.05))
                .foregroundStyle(showSaved ? .green : .secondary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Close hint
            Text("Space to close")
                .font(.system(size: 9))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Image Panel (A/B with slider)

    private var imagePanel: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.92)

                if let image {
                    let imgAspect = image.size.width / image.size.height
                    let padding: CGFloat = 24
                    let availW = geo.size.width - padding * 2
                    let availH = geo.size.height - padding * 2
                    let fitWidth = imgAspect > (availW / availH)
                    let displayW = fitWidth ? availW : availH * imgAspect
                    let displayH = fitWidth ? availW / imgAspect : availH

                    ZStack {
                        // Base screenshot
                        Image(nsImage: image)
                            .resizable()
                            .frame(width: displayW, height: displayH)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        // A/B divider line
                        Rectangle()
                            .fill(.white.opacity(0.6))
                            .frame(width: 2, height: displayH)
                            .position(x: displayW * sliderPosition, y: displayH / 2)

                        // Labels
                        VStack {
                            HStack {
                                Text("CURRENT")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.black.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .padding(8)

                                Spacer()

                                Text("EXPECTED")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.black.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .padding(8)
                            }
                            Spacer()
                        }
                        .frame(width: displayW, height: displayH)

                        // Annotation overlays (above labels, clipped to image bounds)
                        annotationOverlays(size: CGSize(width: displayW, height: displayH))
                            .clipped()
                    }
                    .frame(width: displayW, height: displayH)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.5), radius: 16, y: 4)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                    // Slider control at bottom
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Text("Current")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.5))
                            Slider(value: $sliderPosition, in: 0...1)
                                .frame(width: 200)
                                .tint(.white.opacity(0.3))
                            Text("Expected")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 28))
                            .foregroundStyle(.gray)
                        Text("No screenshot available")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }

    /// Draw annotation overlays on the "expected" side of the slider.
    private func annotationOverlays(size: CGSize) -> some View {
        let positions = markerPositions(count: screen.discrepancies.count, in: size)

        return ZStack {
            ForEach(Array(screen.discrepancies.enumerated()), id: \.offset) { index, disc in
                let pos = index < positions.count ? positions[index] : CGPoint(x: 20, y: 20)
                let isSelected = selectedIssue == index + 1

                // Only show on the "expected" side of the slider
                if pos.x > size.width * sliderPosition - 20 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedIssue = isSelected ? nil : index + 1
                        }
                    } label: {
                        VStack(spacing: 2) {
                            // Marker circle
                            ZStack {
                                // Pulsing ring for open issues
                                if disc.status == .open {
                                    Circle()
                                        .stroke(markerColor(disc.severity).opacity(0.3), lineWidth: 1)
                                        .frame(width: isSelected ? 48 : 36, height: isSelected ? 48 : 36)
                                }
                                Circle()
                                    .fill(markerColor(disc.severity).opacity(isSelected ? 0.3 : 0.15))
                                    .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                                Circle()
                                    .stroke(markerColor(disc.severity), lineWidth: isSelected ? 2.5 : 1.5)
                                    .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                                Text("\(index + 1)")
                                    .font(.system(size: isSelected ? 12 : 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }

                            // Mini label below marker
                            if isSelected {
                                VStack(spacing: 1) {
                                    Text(disc.type.rawValue)
                                        .font(.system(size: 8, weight: .bold))
                                        .textCase(.uppercase)
                                    if !disc.expected.isEmpty {
                                        Text(disc.expected)
                                            .font(.system(size: 8, design: .monospaced))
                                    }
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(markerColor(disc.severity).opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                            }
                        }
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .position(pos)
                    .animation(.spring(response: 0.25), value: isSelected)
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func markerPositions(count: Int, in size: CGSize) -> [CGPoint] {
        let regions: [(CGFloat, CGFloat)] = [
            (0.5, 0.10), (0.25, 0.28), (0.75, 0.22), (0.5, 0.48),
            (0.30, 0.68), (0.70, 0.62), (0.5, 0.82), (0.20, 0.45),
            (0.80, 0.38), (0.5, 0.30),
        ]
        return (0..<min(count, regions.count)).map { i in
            CGPoint(x: size.width * regions[i].0, y: size.height * regions[i].1)
        }
    }

    // MARK: - Issue Panel

    private var issuePanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Issues")
                    .font(.system(size: 12, weight: .semibold))
                Text("(\(screen.discrepancies.count))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider().opacity(0.5)

            // Issue list
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(Array(screen.discrepancies.enumerated()), id: \.offset) { index, disc in
                        issueCard(index: index + 1, disc: disc)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func issueCard(index: Int, disc: Discrepancy) -> some View {
        let isSelected = selectedIssue == index

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedIssue = isSelected ? nil : index
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                // Header: number + severity + type + status
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(markerColor(disc.severity))
                            .frame(width: 20, height: 20)
                        Text("\(index)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }

                    Text(disc.severity.rawValue.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(markerColor(disc.severity))

                    Text(disc.type.rawValue)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Image(systemName: disc.status == .fixed ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(disc.status == .fixed ? .green : .orange)
                }

                // Element
                Text(disc.element)
                    .font(.system(size: 11, weight: .medium))

                // Expected vs Actual — visual comparison
                if !disc.expected.isEmpty && !disc.actual.isEmpty {
                    expectedVsActual(disc: disc)
                }

                // Fix hint
                if let hint = disc.fixHint {
                    Text(hint)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.blue.opacity(0.7))
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }

                // Action buttons
                HStack(spacing: 6) {
                    Text("\(Int(disc.confidence * 100))%")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.quaternary)

                    Spacer()

                    if disc.fixHint != nil {
                        Button {
                            service?.copyFix(disc)
                            copiedIndex = index
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedIndex = nil }
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: copiedIndex == index ? "checkmark" : "doc.on.clipboard")
                                    .font(.system(size: 8))
                                Text(copiedIndex == index ? "Copied" : "Copy")
                                    .font(.system(size: 9))
                            }
                            .foregroundStyle(copiedIndex == index ? .green : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    if disc.status == .open {
                        Button {
                            service?.fixWithClaude(screen: screen, discrepancy: disc)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 8))
                                Text("Fix in Claude")
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? markerColor(disc.severity).opacity(0.05) : Color.primary.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? markerColor(disc.severity).opacity(0.25) : Color.primary.opacity(0.04), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    /// Visual expected vs actual comparison with color swatches or spacing rulers.
    private func expectedVsActual(disc: Discrepancy) -> some View {
        HStack(spacing: 0) {
            // Expected
            VStack(alignment: .leading, spacing: 3) {
                Text("EXPECTED")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.green.opacity(0.6))

                HStack(spacing: 4) {
                    // Color swatch if it's a color issue
                    if disc.type == .color, let color = parseHexColor(disc.expected) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(nsColor: color))
                            .frame(width: 16, height: 16)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(.white.opacity(0.2), lineWidth: 0.5))
                    }

                    // Spacing ruler if it's spacing
                    if disc.type == .spacing {
                        spacingRuler(value: disc.expected, color: .green)
                    }

                    Text(disc.expected)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.green.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.right")
                .font(.system(size: 8))
                .foregroundStyle(.quaternary)
                .padding(.horizontal, 6)

            // Actual
            VStack(alignment: .leading, spacing: 3) {
                Text("ACTUAL")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.red.opacity(0.6))

                HStack(spacing: 4) {
                    if disc.type == .color, let color = parseHexColor(disc.actual) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(nsColor: color))
                            .frame(width: 16, height: 16)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(.white.opacity(0.2), lineWidth: 0.5))
                    }

                    if disc.type == .spacing {
                        spacingRuler(value: disc.actual, color: .red)
                    }

                    Text(disc.actual)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.red.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    /// Visual spacing ruler.
    private func spacingRuler(value: String, color: Color) -> some View {
        let numericValue = Int(value.replacingOccurrences(of: "pt", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
        let barWidth = CGFloat(min(numericValue * 2, 60))

        return HStack(spacing: 0) {
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(width: barWidth, height: 8)
                .overlay(
                    Rectangle()
                        .stroke(color.opacity(0.5), lineWidth: 0.5)
                )
        }
    }

    /// Parse hex color string to NSColor.
    private func parseHexColor(_ hex: String) -> NSColor? {
        let cleaned = hex.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let val = UInt64(cleaned, radix: 16) else { return nil }
        let r = CGFloat((val >> 16) & 0xFF) / 255.0
        let g = CGFloat((val >> 8) & 0xFF) / 255.0
        let b = CGFloat(val & 0xFF) / 255.0
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    // MARK: - Helpers

    private var scoreColor: Color {
        switch screen.score.scoreColor {
        case .pass: return .green
        case .warning: return .yellow
        case .fail: return .red
        }
    }

    private var statusSymbol: String {
        switch screen.score.scoreColor {
        case .pass: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .fail: return "xmark.circle.fill"
        }
    }

    private func markerColor(_ severity: Severity) -> Color {
        switch severity {
        case .critical: return .red
        case .major: return .orange
        case .minor: return .yellow
        case .cosmetic: return .gray
        }
    }

    private func saveReport() {
        guard let dir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd_HHmmss"
        let url = dir.appendingPathComponent("\(screen.name)_report_\(f.string(from: Date())).txt")

        var lines = [
            "Drift Report: \(screen.name)",
            "Score: \(screen.score.scoreFormatted)",
            "File: \(screen.filePath)",
            "Issues: \(screen.discrepancies.count)",
            String(repeating: "─", count: 50),
        ]
        for (i, d) in screen.discrepancies.enumerated() {
            lines.append("\n[\(i+1)] \(d.severity.rawValue.uppercased()) — \(d.type.rawValue)")
            lines.append("    Element: \(d.element)")
            lines.append("    Expected: \(d.expected)  →  Actual: \(d.actual)")
            lines.append("    Status: \(d.status.rawValue)  |  Confidence: \(Int(d.confidence * 100))%")
            if let h = d.fixHint { lines.append("    Fix: \(h)") }
        }
        try? lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        showSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSaved = false }
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: dir.path)
    }
}

// MARK: - Window Manager

final class ComparisonWindowManager {
    static let shared = ComparisonWindowManager()
    private var window: NSWindow?

    func open(screen: DriftScreen, image: NSImage?, service: DriftService? = nil) {
        window?.close()
        window = nil

        let view = ComparisonView(screen: screen, image: image, service: service)
        let hostingView = NSHostingView(rootView: view)

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let winW = min(960, screenFrame.width * 0.8)
        let winH = min(680, screenFrame.height * 0.8)

        let w = PreviewKeyWindow(
            contentRect: NSRect(x: 0, y: 0, width: winW, height: winH),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        w.title = "\(screen.name) — Comparison"
        w.contentView = hostingView
        w.minSize = NSSize(width: 700, height: 450)
        w.center()
        w.isReleasedWhenClosed = false
        w.backgroundColor = .black
        w.onSpace = { [weak self] in self?.window?.close(); self?.window = nil }
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
