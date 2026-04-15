import SwiftUI

/// Menu-popover button that opens the Audit window and shows a live violation count badge.
/// Auto-feeds the window the currently-watched project path when present.
struct AuditMenuButton: View {
    @ObservedObject var service: DriftService
    @ObservedObject private var audit = AuditStore.shared

    var body: some View {
        Button(action: open) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)

                if let count = audit.report?.count, count > 0 {
                    Text("\(min(count, 99))\(count > 99 ? "+" : "")")
                        .font(.system(size: 9, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .frame(minWidth: 14, minHeight: 12)
                        .background(Theme.Colors.fail, in: Capsule())
                        .offset(x: 8, y: -6)
                }
            }
            .frame(width: 28, height: 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(helpText)
    }

    private func open() {
        let path = service.settings.watchedProjectPath
        let url = path.isEmpty ? nil : URL(fileURLWithPath: path)
        AuditWindowManager.shared.open(initialDirectory: url)
    }

    private var iconColor: Color {
        guard let report = audit.report else { return Theme.Colors.textDim }
        return report.count == 0 ? Theme.Colors.pass : Theme.Colors.warn
    }

    private var helpText: String {
        guard let report = audit.report else { return "Design audit" }
        if audit.isScanning { return "Auditing…" }
        return "Design audit — \(report.count) issue\(report.count == 1 ? "" : "s")"
    }
}
