import SwiftUI
import AppKit

/// Full-screen preview of a screen screenshot with download support.
struct ScreenPreviewView: View {
    let screenName: String
    let score: Double
    let image: NSImage
    @State private var showSaved = false

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(screenName)
                        .font(.system(size: 14, weight: .semibold))
                    Text("\(Int(image.size.width))×\(Int(image.size.height))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(scoreFormatted)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(scoreColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(scoreColor.opacity(0.1))
                    .clipShape(Capsule())

                // Download button
                Button {
                    saveToDownloads()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showSaved ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 12))
                        Text(showSaved ? "Saved" : "Save JPEG")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(showSaved ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                    .foregroundStyle(showSaved ? .green : .blue)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Image preview — scrollable and zoomable
            ScrollView([.horizontal, .vertical]) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(16)
            }
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }

    private var scoreFormatted: String {
        "\(Int(score * 100))%"
    }

    private var scoreColor: Color {
        if score >= 0.9 { return .green }
        if score >= 0.7 { return .yellow }
        return .red
    }

    private func saveToDownloads() {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        guard let downloadsDir = downloads else { return }

        let fileName = "\(screenName)_\(dateStamp()).jpg"
        let url = downloadsDir.appendingPathComponent(fileName)

        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else { return }

        do {
            try jpeg.write(to: url)
            showSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSaved = false
            }
            // Bounce the Downloads folder in Dock
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: downloadsDir.path)
        } catch {
            // Silent fail
        }
    }

    private func dateStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HHmmss"
        return f.string(from: Date())
    }
}

// MARK: - Window Manager

final class ScreenPreviewWindowManager {
    static let shared = ScreenPreviewWindowManager()
    private var windows: [String: NSWindow] = [:]

    func open(screenName: String, score: Double, image: NSImage) {
        // Close existing preview for this screen
        if let existing = windows[screenName] {
            existing.close()
            windows[screenName] = nil
        }

        let previewView = ScreenPreviewView(screenName: screenName, score: score, image: image)
        let hostingView = NSHostingView(rootView: previewView)

        // Size window to fit image aspect ratio, capped at screen size
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let imgW = image.size.width
        let imgH = image.size.height
        let maxW = min(imgW * 0.5, screenFrame.width * 0.7)
        let scale = maxW / imgW
        let winW = max(360, maxW)
        let winH = min(max(400, imgH * scale + 50), screenFrame.height * 0.85)

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: winW, height: winH),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        w.title = "\(screenName) — Preview"
        w.contentView = hostingView
        w.minSize = NSSize(width: 320, height: 300)
        w.center()
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        windows[screenName] = w
    }
}
