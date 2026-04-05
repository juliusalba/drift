import SwiftUI
import AppKit

/// Quick Look-style preview of a screen screenshot.
struct ScreenPreviewView: View {
    let screenName: String
    let score: Double
    let image: NSImage
    @State private var showSaved = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(screenName)
                        .font(.system(size: 14, weight: .semibold))
                    Text("\(Int(image.size.width))×\(Int(image.size.height))px")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Score
                Text(scoreFormatted)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(scoreColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(scoreColor.opacity(0.1))
                    .clipShape(Capsule())

                // Save
                Button { saveToDownloads() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showSaved ? "checkmark" : "arrow.down.to.line")
                            .font(.system(size: 10, weight: .semibold))
                        Text(showSaved ? "Saved" : "Save")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(showSaved ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                    .foregroundStyle(showSaved ? .green : .blue)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Close hint
                Text("Space to close")
                    .font(.system(size: 9))
                    .foregroundStyle(.quaternary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().opacity(0.5)

            // Image — centered, fits window, dark background
            GeometryReader { geo in
                let imgAspect = image.size.width / image.size.height
                let containerAspect = geo.size.width / geo.size.height
                let fitWidth = imgAspect > containerAspect

                ZStack {
                    Color.black.opacity(0.9)

                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: fitWidth ? geo.size.width - 32 : nil,
                            height: fitWidth ? nil : geo.size.height - 32
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.5), radius: 20, y: 4)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    private var scoreFormatted: String { "\(Int(score * 100))%" }

    private var scoreColor: Color {
        if score >= 0.9 { return .green }
        if score >= 0.7 { return .yellow }
        return .red
    }

    private func saveToDownloads() {
        guard let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }

        let fileName = "\(screenName)_\(dateStamp()).jpg"
        let url = downloadsDir.appendingPathComponent(fileName)

        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else { return }

        do {
            try jpeg.write(to: url)
            showSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSaved = false }
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: downloadsDir.path)
        } catch {
            // Silent
        }
    }

    private func dateStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HHmmss"
        return f.string(from: Date())
    }
}

// MARK: - Preview Window with Keyboard Support

final class PreviewKeyWindow: NSWindow {
    var onSpace: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        // Space or Escape closes the preview
        if event.keyCode == 49 || event.keyCode == 53 { // space = 49, esc = 53
            onSpace?()
        } else {
            super.keyDown(with: event)
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Window Manager

final class ScreenPreviewWindowManager {
    static let shared = ScreenPreviewWindowManager()
    private var window: NSWindow?

    func open(screenName: String, score: Double, image: NSImage) {
        // Close any existing preview
        close()

        let previewView = ScreenPreviewView(
            screenName: screenName,
            score: score,
            image: image
        )
        let hostingView = NSHostingView(rootView: previewView)

        // Size window to image aspect ratio
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let imgW = image.size.width
        let imgH = image.size.height
        let aspect = imgW / imgH

        // For phone screenshots (portrait), make window tall
        let winH = min(screenFrame.height * 0.8, 800.0)
        let winW = max(360, min(winH * aspect + 40, screenFrame.width * 0.6))

        let w = PreviewKeyWindow(
            contentRect: NSRect(x: 0, y: 0, width: winW, height: winH),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        w.title = "\(screenName)"
        w.contentView = hostingView
        w.minSize = NSSize(width: 280, height: 300)
        w.center()
        w.isReleasedWhenClosed = false
        w.titlebarAppearsTransparent = true
        w.backgroundColor = .black
        w.onSpace = { [weak self] in self?.close() }
        w.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        window = w
    }

    func close() {
        window?.close()
        window = nil
    }
}
