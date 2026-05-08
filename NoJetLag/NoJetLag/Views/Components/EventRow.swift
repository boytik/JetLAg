import SwiftUI

/// A single event row inside the plan timeline. Mono time on the left,
/// short action label, colored badge on the right.
struct EventRow: View {
    let event: PlanEvent

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Text(timeText)
                .font(Typography.mono(13, weight: .semibold))
                .foregroundStyle(Color.textHi)
                .frame(width: 56, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.kind.title)
                    .font(Typography.body(13, weight: .medium))
                    .foregroundStyle(Color.textMid)
                if let note = event.note {
                    Text(note)
                        .font(Typography.body(12))
                        .foregroundStyle(Color.textLo)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: Spacing.sm)

            EventBadge(kind: event.kind)
        }
        .padding(.vertical, Spacing.sm)
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeZone = event.displayTimeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.startsAt)
    }
}
