import SwiftUI
import AppKit

/// A/B comparison view with annotated discrepancies overlaid on the screenshot.
struct ComparisonView: View {
    let screen: DriftScreen
    let image: NSImage?
    @State private var showAnnotations = true
    @State private var selectedIssue: Int? = nil
    @State private var showSaved = false

    var body: some View {
        HSplitView {
            // Left: Annotated screenshot
            screenshotPanel
                .frame(minWidth: 280)

            // Right: Issue list
            issuePanel
                .frame(width: 280)
        }
    }

    // MARK: - Screenshot Panel

    private var screenshotPanel: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(screen.name)
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                // Toggle annotations
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAnnotations.toggle()
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: showAnnotations ? "eye.fill" : "eye.slash")
                            .font(.system(size: 10))
                        Text(showAnnotations ? "Hide Markers" : "Show Markers")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                HStack(spacing: 3) {
                    Image(systemName: statusSymbol)
                        .font(.system(size: 10))
                    Text(screen.score.scoreFormatted)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(scoreColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().opacity(0.5)

            // Screenshot with annotations
            GeometryReader { geo in
                ZStack {
                    Color.black.opacity(0.9)

                    if let image {
                        let imgAspect = image.size.width / image.size.height
                        let containerAspect = geo.size.width / geo.size.height
                        let fitWidth = imgAspect > containerAspect
                        let displayW = fitWidth ? geo.size.width - 32 : (geo.size.height - 32) * imgAspect
                        let displayH = fitWidth ? (geo.size.width - 32) / imgAspect : geo.size.height - 32

                        ZStack(alignment: .topLeading) {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: displayW, height: displayH)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(color: .black.opacity(0.5), radius: 20, y: 4)

                            // Annotation markers
                            if showAnnotations {
                                ForEach(Array(screen.discrepancies.enumerated()), id: \.offset) { index, disc in
                                    annotationMarker(
                                        index: index + 1,
                                        disc: disc,
                                        displaySize: CGSize(width: displayW, height: displayH)
                                    )
                                }
                            }
                        }
                        .frame(width: displayW, height: displayH)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.system(size: 28))
                                .foregroundStyle(.tertiary)
                            Text("No screenshot available")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }

    private func annotationMarker(index: Int, disc: Discrepancy, displaySize: CGSize) -> some View {
        // Distribute markers across the screen based on index
        let positions = markerPositions(count: screen.discrepancies.count, in: displaySize)
        let pos = index <= positions.count ? positions[index - 1] : CGPoint(x: 20, y: 20)
        let isSelected = selectedIssue == index

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedIssue = isSelected ? nil : index
            }
        } label: {
            ZStack {
                // Highlight circle
                Circle()
                    .stroke(markerColor(disc.severity), lineWidth: isSelected ? 3 : 2)
                    .fill(markerColor(disc.severity).opacity(isSelected ? 0.25 : 0.1))
                    .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)

                // Number
                Text("\(index)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .position(pos)
        .animation(.spring(response: 0.3), value: isSelected)
    }

    /// Distribute annotation markers across the screenshot intelligently.
    private func markerPositions(count: Int, in size: CGSize) -> [CGPoint] {
        guard count > 0 else { return [] }

        // Place markers at key UI regions (top header, middle content, bottom CTA)
        let regions: [(CGFloat, CGFloat)] = [
            (0.5, 0.08),  // Top center (nav bar area)
            (0.25, 0.25), // Left upper (sidebar/labels)
            (0.75, 0.20), // Right upper (buttons/icons)
            (0.5, 0.45),  // Center (main content)
            (0.3, 0.65),  // Left lower
            (0.7, 0.60),  // Right lower
            (0.5, 0.80),  // Bottom center (CTA area)
            (0.2, 0.50),  // Left middle
            (0.8, 0.40),  // Right middle
            (0.5, 0.30),  // Upper center
        ]

        var points: [CGPoint] = []
        for i in 0..<min(count, regions.count) {
            let (rx, ry) = regions[i]
            points.append(CGPoint(
                x: size.width * rx,
                y: size.height * ry
            ))
        }
        return points
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

                // Save report
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
                    .padding(.vertical, 4)
                    .background(showSaved ? Color.green.opacity(0.1) : Color.primary.opacity(0.05))
                    .foregroundStyle(showSaved ? .green : .primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider().opacity(0.5)

            // Summary bar
            HStack(spacing: 12) {
                let open = screen.discrepancies.filter { $0.status == .open }.count
                let fixed = screen.discrepancies.filter { $0.status == .fixed }.count
                summaryPill("\(open) Open", color: .orange, icon: "exclamationmark.circle")
                summaryPill("\(fixed) Fixed", color: .green, icon: "checkmark.circle.fill")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider().opacity(0.3)

            // Issue list
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(Array(screen.discrepancies.enumerated()), id: \.offset) { index, disc in
                        issueRow(index: index + 1, disc: disc)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }

            // File path footer
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 9))
                    .foregroundStyle(.quaternary)
                Text(screen.filePath)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.quaternary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.02))
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func issueRow(index: Int, disc: Discrepancy) -> some View {
        let isSelected = selectedIssue == index

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedIssue = isSelected ? nil : index
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // Number marker
                    ZStack {
                        Circle()
                            .fill(markerColor(disc.severity))
                            .frame(width: 18, height: 18)
                        Text("\(index)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }

                    // Severity
                    Text(disc.severity.rawValue.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(markerColor(disc.severity))

                    Text(disc.type.rawValue)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.tertiary)

                    Spacer()

                    // Status
                    Image(systemName: disc.status == .fixed ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(disc.status == .fixed ? .green : .orange)
                }

                // Element name
                Text(disc.element)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)

                // Expected vs Actual
                if !disc.expected.isEmpty && !disc.actual.isEmpty {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Expected")
                                .font(.system(size: 8))
                                .foregroundStyle(.quaternary)
                            Text(disc.expected)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.green.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 8))
                            .foregroundStyle(.quaternary)
                            .padding(.horizontal, 4)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Actual")
                                .font(.system(size: 8))
                                .foregroundStyle(.quaternary)
                            Text(disc.actual)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(6)
                    .background(Color.primary.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                // Fix hint
                if let hint = disc.fixHint {
                    HStack(spacing: 4) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 8))
                            .foregroundStyle(.blue.opacity(0.6))
                        Text(hint)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.blue.opacity(0.6))
                            .lineLimit(2)
                    }
                    .padding(6)
                    .background(Color.blue.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                // Confidence
                HStack(spacing: 4) {
                    Text("Confidence:")
                        .font(.system(size: 8))
                        .foregroundStyle(.quaternary)
                    Text("\(Int(disc.confidence * 100))%")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? markerColor(disc.severity).opacity(0.06) : Color.primary.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? markerColor(disc.severity).opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func summaryPill(_ text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
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
        guard let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HHmmss"
        let fileName = "\(screen.name)_report_\(f.string(from: Date())).txt"
        let url = downloadsDir.appendingPathComponent(fileName)

        var lines = [
            "Drift Report: \(screen.name)",
            "Score: \(screen.score.scoreFormatted)",
            "File: \(screen.filePath)",
            "Issues: \(screen.discrepancies.count)",
            "---",
        ]

        for (i, disc) in screen.discrepancies.enumerated() {
            lines.append("\n[\(i + 1)] \(disc.severity.rawValue.uppercased()) — \(disc.type.rawValue)")
            lines.append("    Element: \(disc.element)")
            lines.append("    Expected: \(disc.expected)")
            lines.append("    Actual: \(disc.actual)")
            lines.append("    Status: \(disc.status.rawValue)")
            lines.append("    Confidence: \(Int(disc.confidence * 100))%")
            if let hint = disc.fixHint {
                lines.append("    Fix: \(hint)")
            }
        }

        let content = lines.joined(separator: "\n")
        try? content.write(to: url, atomically: true, encoding: .utf8)

        showSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSaved = false }
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: downloadsDir.path)
    }
}

// MARK: - Comparison Window Manager

final class ComparisonWindowManager {
    static let shared = ComparisonWindowManager()
    private var window: NSWindow?

    func open(screen: DriftScreen, image: NSImage?) {
        window?.close()
        window = nil

        let view = ComparisonView(screen: screen, image: image)
        let hostingView = NSHostingView(rootView: view)

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let winW = min(900, screenFrame.width * 0.75)
        let winH = min(650, screenFrame.height * 0.75)

        let w = PreviewKeyWindow(
            contentRect: NSRect(x: 0, y: 0, width: winW, height: winH),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        w.title = "\(screen.name) — Comparison Report"
        w.contentView = hostingView
        w.minSize = NSSize(width: 600, height: 400)
        w.center()
        w.isReleasedWhenClosed = false
        w.onSpace = { [weak self] in
            self?.window?.close()
            self?.window = nil
        }
        w.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
