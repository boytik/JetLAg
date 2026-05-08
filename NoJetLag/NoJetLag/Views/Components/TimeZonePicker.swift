import SwiftUI

/// A searchable list of IANA timezone identifiers. Tapping a row writes its
/// identifier back to the bound selection and dismisses the view.
struct TimeZonePicker: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var allIdentifiers: [String] {
        TimeZone.knownTimeZoneIdentifiers.sorted()
    }

    private var filtered: [String] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return allIdentifiers }
        return allIdentifiers.filter { $0.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg0.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filtered, id: \.self) { id in
                            row(for: id)
                            Hairline()
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
            }
            .navigationTitle("TIME ZONE")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search city")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CANCEL") { dismiss() }
                        .font(Typography.mono(11, weight: .semibold))
                        .foregroundStyle(Color.textLo)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for id: String) -> some View {
        Button {
            selection = id
            dismiss()
        } label: {
            HStack(alignment: .center, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName(for: id))
                        .font(Typography.body(15, weight: .medium))
                        .foregroundStyle(Color.textHi)
                    Text(id)
                        .font(Typography.mono(11))
                        .foregroundStyle(Color.textLo)
                }
                Spacer()
                Text(offsetLabel(for: id))
                    .font(Typography.mono(12, weight: .medium))
                    .foregroundStyle(Color.textMid)
                if id == selection {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.amber)
                }
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }

    private func displayName(for id: String) -> String {
        id.split(separator: "/").last
            .map { String($0).replacingOccurrences(of: "_", with: " ") }
            ?? id
    }

    private func offsetLabel(for id: String) -> String {
        guard let tz = TimeZone(identifier: id) else { return "" }
        let secs = tz.secondsFromGMT()
        let sign = secs >= 0 ? "+" : "-"
        let mag = abs(secs)
        let h = mag / 3600
        let m = (mag % 3600) / 60
        return String(format: "GMT%@%d:%02d", sign, h, m)
    }
}
