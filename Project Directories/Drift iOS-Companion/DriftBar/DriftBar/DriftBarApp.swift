import SwiftUI

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

        Settings {
            SettingsView(service: service)
        }
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
