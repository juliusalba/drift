import SwiftUI
import AppKit

@MainActor
final class AuditWindowManager: NSObject, NSWindowDelegate {
    static let shared = AuditWindowManager()
    private var window: NSWindow?
    private var hostingView: NSHostingView<AuditView>?
    let store = AuditStore.shared

    func open(initialDirectory: URL? = nil) {
        dismissMenuBarPopover()

        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            if let dir = initialDirectory { store.scan(at: dir) }
            return
        }

        let view = AuditView(store: store)
        let host = NSHostingView(rootView: view)
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        w.title = "Drift Audit"
        w.contentView = host
        w.minSize = NSSize(width: 720, height: 520)
        w.center()
        w.isReleasedWhenClosed = false
        w.delegate = self
        w.backgroundColor = NSColor.windowBackgroundColor
        w.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        window = w
        hostingView = host

        if let dir = initialDirectory { store.scan(at: dir) }
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        hostingView = nil
    }

    private func dismissMenuBarPopover() {
        for win in NSApp.windows {
            let typeName = String(describing: type(of: win))
            if typeName.contains("StatusBar") || typeName.contains("MenuBarExtra") {
                win.close()
            }
        }
    }
}
