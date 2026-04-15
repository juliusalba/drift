import SwiftUI
import AppKit
import WebKit

final class HelpWindowManager: NSObject, NSWindowDelegate {
    static let shared = HelpWindowManager()
    private var window: NSWindow?

    func open() {
        dismissMenuBarPopover()

        if let existing = window {
            if existing.isVisible {
                existing.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
            window = nil
        }

        let webView = makeWebView()

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.title = "How to use Drift"
        w.titlebarAppearsTransparent = true
        w.contentView = webView
        w.minSize = NSSize(width: 760, height: 520)
        w.center()
        w.isReleasedWhenClosed = false
        w.delegate = self
        w.backgroundColor = NSColor.windowBackgroundColor
        w.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        window = w
    }

    private func makeWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        if let indexURL = Bundle.main.url(
            forResource: "index",
            withExtension: "html",
            subdirectory: "Help"
        ) {
            webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
        } else {
            let html = """
            <html><body style="font-family:-apple-system;padding:48px;color:#888">
            <h2>Help content missing</h2>
            <p>The <code>Help/</code> folder is not bundled with the app.
            Drag <code>DriftBar/DriftBar/Help</code> into the Xcode target as a folder reference.</p>
            </body></html>
            """
            webView.loadHTMLString(html, baseURL: nil)
        }
        return webView
    }

    func windowWillClose(_ notification: Notification) { window = nil }

    private func dismissMenuBarPopover() {
        for win in NSApp.windows {
            let typeName = String(describing: type(of: win))
            if typeName.contains("StatusBar") || typeName.contains("MenuBarExtra") {
                win.close()
            }
        }
    }
}
