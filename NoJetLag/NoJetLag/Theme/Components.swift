import SwiftUI

// =====================================================================
// Reusable instrument-panel components.
// All views here read from Theme.swift tokens — never hardcode hex.
// =====================================================================

// MARK: - Cards

/// A card surface with a 1px stroke. No soft shadows — pure flat panel.
struct InstrumentCard<Content: View>: View {
    var padding: CGFloat = Spacing.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Color.bg1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.stroke, lineWidth: 1)
            )
    }
}

/// Active "RIGHT NOW" card — amber stroke + leading amber bar + subtle wash.
struct ActiveCard<Content: View>: View {
    var padding: CGFloat = Spacing.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(padding)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.bg1)
                )
                .background(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.amber.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.amber, lineWidth: 1)
                )

            // Leading amber bar
            Rectangle()
                .fill(Color.amber)
                .frame(width: 3, height: 24)
                .offset(x: 0, y: Spacing.lg)
        }
    }
}

// MARK: - Pulsing dot (the one signature animation)

struct PulsingDot: View {
    var color: Color = .amber
    var size: CGFloat = 6
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(color.opacity(pulse ? 0 : 0.5), lineWidth: 1)
                    .scaleEffect(pulse ? 2.6 : 1)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
    }
}

// MARK: - Event badge (LIGHT / AVOID / SLEEP / CAF / FLIGHT)

struct EventBadge: View {
    let kind: PlanEventKind

    var body: some View {
        Text(label)
            .font(Typography.mono(9, weight: .semibold))
            .trackedUppercase(1.4)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .stroke(color, lineWidth: 1)
            )
    }

    private var label: String {
        switch kind {
        case .seekLight:     return "LIGHT"
        case .avoidLight:    return "AVOID"
        case .takeMelatonin: return "SLEEP"
        case .sleep:         return "SLEEP"
        case .wake:          return "WAKE"
        case .caffeineAvoid: return "CAF"
        case .flight:        return "FLIGHT"
        }
    }

    private var color: Color {
        switch kind {
        case .seekLight:     return .amber
        case .avoidLight:    return .advisoryRed
        case .takeMelatonin: return .sleepIndigo
        case .sleep:         return .sleepIndigo
        case .wake:          return .sleepIndigo
        case .caffeineAvoid: return .caffeineGreen
        case .flight:        return .textMid
        }
    }
}

// MARK: - Altitude rule (vertical timeline ruler)

/// Thin vertical line with repeating tick marks every 12pt — sits on the
/// leading edge of timeline cards. Reads as an altimeter rule.
struct AltitudeRule: View {
    var body: some View {
        Canvas { ctx, size in
            // Solid spine
            ctx.fill(
                Path(CGRect(x: 0, y: 0, width: 1, height: size.height)),
                with: .color(.strokeStrong)
            )
            // Repeating ticks every 12pt
            var y: CGFloat = 0
            while y <= size.height {
                ctx.fill(
                    Path(CGRect(x: 0, y: y, width: 5, height: 1)),
                    with: .color(.strokeStrong)
                )
                y += 12
            }
        }
        .frame(width: 5)
    }
}

// MARK: - Tracked section heading (mono uppercase tag)

struct SectionTag: View {
    let text: String
    var color: Color = .textLo
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(text)
                .font(Typography.mono(10, weight: .semibold))
                .trackedUppercase(1.6)
                .foregroundStyle(color)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
            }
        }
    }
}

// MARK: - Primary instrument button style

struct InstrumentButtonStyle: ButtonStyle {
    var role: Role = .primary

    enum Role { case primary, secondary, destructive }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.body(15, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }

    private var foreground: Color {
        switch role {
        case .primary:     return .bg0
        case .secondary:   return .textHi
        case .destructive: return .advisoryRed
        }
    }
    private var background: Color {
        switch role {
        case .primary:     return .amber
        case .secondary:   return .bg1
        case .destructive: return .bg1
        }
    }
    private var strokeColor: Color {
        switch role {
        case .primary:     return .amber
        case .secondary:   return .stroke
        case .destructive: return .advisoryRed.opacity(0.5)
        }
    }
}

extension ButtonStyle where Self == InstrumentButtonStyle {
    static var instrument: InstrumentButtonStyle { InstrumentButtonStyle(role: .primary) }
    static var instrumentSecondary: InstrumentButtonStyle { InstrumentButtonStyle(role: .secondary) }
    static var instrumentDestructive: InstrumentButtonStyle { InstrumentButtonStyle(role: .destructive) }
}

// MARK: - Hairline divider (1px stroke color, no inset)

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Color.stroke)
            .frame(height: 1)
    }
}
