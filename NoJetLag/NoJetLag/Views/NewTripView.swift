import SwiftUI

/// Form for creating (or editing) a single trip.
struct NewTripView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var originTZ: String      = TimeZone.current.identifier
    @State private var destinationTZ: String = TimeZone.current.identifier
    @State private var departure: Date       = defaultDeparture()
    @State private var arrival: Date         = defaultArrival()

    @State private var showingOriginPicker = false
    @State private var showingDestPicker   = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Route") {
                    Button {
                        showingOriginPicker = true
                    } label: {
                        labeledField("From", value: cityName(originTZ), accessory: offsetLabel(originTZ))
                    }
                    Button {
                        showingDestPicker = true
                    } label: {
                        labeledField("To", value: cityName(destinationTZ), accessory: offsetLabel(destinationTZ))
                    }
                }

                Section("Schedule") {
                    DatePicker("Departure", selection: $departure)
                    DatePicker("Arrival",   selection: $arrival, in: departure...)
                }

                if let preview = shiftPreview {
                    Section {
                        HStack {
                            Image(systemName: preview.icon)
                                .foregroundStyle(.tint)
                            Text(preview.text)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Direction")
                    }
                }
            }
            .navigationTitle(state.trip == nil ? "Plan a trip" : "Edit trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(originTZ == destinationTZ)
                }
            }
            .sheet(isPresented: $showingOriginPicker) {
                TimeZonePicker(selection: $originTZ)
            }
            .sheet(isPresented: $showingDestPicker) {
                TimeZonePicker(selection: $destinationTZ)
            }
            .onAppear(perform: hydrateFromExistingTrip)
        }
    }

    // MARK: - Pieces

    @ViewBuilder
    private func labeledField(_ label: String, value: String, accessory: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .foregroundStyle(.primary)
                Text(accessory)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private struct ShiftPreview {
        let text: String
        let icon: String
    }

    private var shiftPreview: ShiftPreview? {
        guard originTZ != destinationTZ,
              let oTZ = TimeZone(identifier: originTZ),
              let dTZ = TimeZone(identifier: destinationTZ)
        else { return nil }

        let now = arrival
        var delta = (Double(dTZ.secondsFromGMT(for: now)) - Double(oTZ.secondsFromGMT(for: now))) / 3600
        if delta > 12 { delta -= 24 }
        if delta < -12 { delta += 24 }

        let absStr = String(format: "%.1f", abs(delta))
        if abs(delta) < 1 {
            return .init(text: "Same timezone — no jet lag protocol needed.", icon: "checkmark.circle.fill")
        }
        if delta > 0 {
            return .init(text: "Eastward — body must shift \(absStr)h earlier.", icon: "arrow.up.right.circle.fill")
        }
        return .init(text: "Westward — body must shift \(absStr)h later.", icon: "arrow.down.right.circle.fill")
    }

    // MARK: - Helpers

    private func cityName(_ id: String) -> String {
        id.split(separator: "/").last
            .map { String($0).replacingOccurrences(of: "_", with: " ") }
            ?? id
    }

    private func offsetLabel(_ id: String) -> String {
        guard let tz = TimeZone(identifier: id) else { return id }
        let secs = tz.secondsFromGMT(for: arrival)
        let sign = secs >= 0 ? "+" : "-"
        let mag = abs(secs)
        return String(format: "GMT%@%d:%02d  •  %@", sign, mag / 3600, (mag % 3600) / 60, id)
    }

    private func hydrateFromExistingTrip() {
        guard let t = state.trip else { return }
        originTZ      = t.originTimeZoneId
        destinationTZ = t.destinationTimeZoneId
        departure     = t.departure
        arrival       = t.arrival
    }

    private func save() {
        let trip = Trip(
            id: state.trip?.id ?? UUID(),
            name: Trip.defaultName(for: originTZ, destination: destinationTZ),
            originTimeZoneId: originTZ,
            destinationTimeZoneId: destinationTZ,
            departure: departure,
            arrival: arrival
        )
        state.trip = trip
        dismiss()
    }

    private static func defaultDeparture() -> Date {
        Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }

    private static func defaultArrival() -> Date {
        Calendar.current.date(byAdding: .hour, value: 10, to: defaultDeparture()) ?? Date()
    }
}
