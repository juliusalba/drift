import SwiftUI
import AppKit

@main
struct DriftBarApp: App {
    @StateObject private var service = DriftService()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(service: service)
                .onAppear {
                    service.startWatching()
                }
        } label: {
            MenuBarLabel(service: service)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu Bar Icon

struct MenuBarLabel: View {
    @ObservedObject var service: DriftService

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("MenuBarIcon")
                .renderingMode(.template)

            Circle()
                .fill(statusColor)
                .frame(width: 5, height: 5)
                .offset(x: 1, y: 1)
        }
    }

    private var statusColor: Color {
        guard let run = service.latestRun else { return .gray }
        switch run.summary.overallScore.scoreColor {
        case .pass: return .green
        case .warning: return .yellow
        case .fail: return .red
        }
    }
}

// MARK: - Settings Window Manager

final class SettingsWindowManager: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowManager()
    private var window: NSWindow?

    func open(service: DriftService) {
        // If window exists and is visible, just bring it forward
        if let existing = window {
            if existing.isVisible {
                existing.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
            // Window was closed — release it and create fresh
            window = nil
        }

        let settingsView = SettingsView(service: service)
        let hostingView = NSHostingView(rootView: settingsView)

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        w.title = "Drift Settings"
        w.contentView = hostingView
        w.minSize = NSSize(width: 440, height: 480)
        w.center()
        w.isReleasedWhenClosed = false
        w.delegate = self
        w.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        window = w
    }

    // Release window reference when user closes it
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
