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

    private var statusText: String {
        guard let run = service.latestRun else { return "No data" }
        return "Score: \(run.summary.overallScore.scoreFormatted)"
    }
}

extension MenuBarLabel {
    var accessibilityDescription: String { statusText }
}

// MARK: - Settings Window Manager

final class SettingsWindowManager: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowManager()
    private var window: NSWindow?

    func open(service: DriftService) {
        // Close the menu bar popover by removing focus from it
        dismissMenuBarPopover()

        if let existing = window {
            if existing.isVisible {
                existing.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
            window = nil
        }

        let settingsView = SettingsView(service: service)
        let hostingView = NSHostingView(rootView: settingsView)

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        w.title = "Drift Settings"
        w.contentView = hostingView
        w.minSize = NSSize(width: 460, height: 500)
        w.center()
        w.isReleasedWhenClosed = false
        w.delegate = self
        w.backgroundColor = NSColor.windowBackgroundColor
        w.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        window = w
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }

    private func dismissMenuBarPopover() {
        // Find and close any MenuBarExtra popover windows
        for win in NSApp.windows {
            let typeName = String(describing: type(of: win))
            if typeName.contains("StatusBar") || typeName.contains("MenuBarExtra") {
                win.close()
            }
        }
    }
}
