import SwiftUI

/// A single event row inside the plan timeline.
struct EventRow: View {
    let event: PlanEvent

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: event.kind.icon)
                    .foregroundStyle(tint)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(event.kind.title)
                        .font(.body.weight(.semibold))
                    Spacer()
                    Text(timeRangeText)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                if let note = event.note {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var tint: Color {
        switch event.kind {
        case .seekLight:     return .orange
        case .avoidLight:    return .indigo
        case .takeMelatonin: return .purple
        case .sleep:         return .blue
        case .wake:          return .teal
        case .caffeineAvoid: return .brown
        case .flight:        return .pink
        }
    }

    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeZone = event.displayTimeZone
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let start = formatter.string(from: event.startsAt)
        if let end = event.endsAt {
            return "\(start) – \(formatter.string(from: end))"
        }
        return start
    }
}
