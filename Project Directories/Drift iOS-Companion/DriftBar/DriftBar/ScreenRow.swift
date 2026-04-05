import SwiftUI

struct ScreenRow: View {
    let screen: DriftScreen
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Score dot
            Circle()
                .fill(scoreColor)
                .frame(width: 6, height: 6)

            // Name
            Text(screen.name)
                .font(.system(size: 12))
                .lineLimit(1)

            Spacer()

            // Issue count
            if !screen.discrepancies.isEmpty {
                let openCount = screen.discrepancies.filter { $0.status == .open }.count
                if openCount > 0 {
                    Text("\(openCount)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }

            // Score
            Text(screen.score.scoreFormatted)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(scoreColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color.primary.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
    }

    private var scoreColor: Color {
        switch screen.score.scoreColor {
        case .pass: return .green
        case .warning: return .yellow
        case .fail: return .red
        }
    }
}

// MARK: - Inline Detail (expands below selected screen)

struct ScreenDetailInline: View {
    let screen: DriftScreen

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // File path
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                Text(screen.filePath)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            if screen.discrepancies.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                    Text("No discrepancies")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(screen.discrepancies) { disc in
                    DiscrepancyRow(discrepancy: disc)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.03))
    }
}

struct DiscrepancyRow: View {
    let discrepancy: Discrepancy

    var body: some View {
        HStack(spacing: 6) {
            // Severity
            Text(discrepancy.severity.rawValue)
                .font(.system(size: 9, weight: .medium))
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(severityColor.opacity(0.12))
                .foregroundStyle(severityColor)
                .clipShape(Capsule())

            // Type
            Text(discrepancy.type.rawValue)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 48, alignment: .leading)

            // Element
            Text(discrepancy.element)
                .font(.system(size: 11))
                .lineLimit(1)

            Spacer()

            // Status icon
            Image(systemName: statusIcon)
                .font(.system(size: 9))
                .foregroundStyle(statusColor)
        }
    }

    private var severityColor: Color {
        switch discrepancy.severity {
        case .critical: return .red
        case .major: return .orange
        case .minor: return .yellow
        case .cosmetic: return .gray
        }
    }

    private var statusIcon: String {
        switch discrepancy.status {
        case .fixed: return "checkmark.circle.fill"
        case .open: return "exclamationmark.circle"
        case .wontFix: return "minus.circle"
        }
    }

    private var statusColor: Color {
        switch discrepancy.status {
        case .fixed: return .green
        case .open: return .orange
        case .wontFix: return .gray
        }
    }
}
