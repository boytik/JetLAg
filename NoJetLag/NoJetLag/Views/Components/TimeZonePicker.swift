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
            List(filtered, id: \.self) { id in
                Button {
                    selection = id
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName(for: id))
                                .foregroundStyle(.primary)
                            Text(id)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(offsetLabel(for: id))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        if id == selection {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
            .navigationTitle("Time zone")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search city")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
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
