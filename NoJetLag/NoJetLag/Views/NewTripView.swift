import SwiftUI

/// Form for creating (or editing) a single trip.
struct NewTripView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var originTZ: String      = TimeZone.current.identifier
    @State private var destinationTZ: String = TimeZone.current.identifier
    @State private var departure: Date       = defaultDeparture()
    @State private var arrival: Date         = defaultArrival()

    @State private var isRoundTrip: Bool     = false
    @State private var returnDeparture: Date = defaultReturnDeparture()
    @State private var returnArrival: Date   = defaultReturnArrival()

    @State private var showingOriginPicker = false
    @State private var showingDestPicker   = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg0.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        routeGroup
                        scheduleGroup
                        roundTripGroup
                        if isRoundTrip {
                            returnScheduleGroup
                            strategyGroup
                        }
                        if let preview = shiftPreview {
                            directionGroup(preview)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationTitle(state.trip == nil ? "PLAN A TRIP" : "EDIT TRIP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CANCEL") { dismiss() }
                        .font(Typography.mono(11, weight: .semibold))
                        .foregroundStyle(Color.textLo)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("SAVE", action: save)
                        .disabled(!isFormValid)
                        .font(Typography.mono(11, weight: .semibold))
                        .foregroundStyle(isFormValid ? Color.amber : Color.textLo)
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

    // MARK: Groups

    private var routeGroup: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "ROUTE")
                .padding(.horizontal, Spacing.xs)
            InstrumentCard(padding: 0) {
                VStack(spacing: 0) {
                    Button { showingOriginPicker = true } label: {
                        routeRow(label: "FROM", tzId: originTZ)
                    }
                    .buttonStyle(.plain)
                    Hairline()
                    Button { showingDestPicker = true } label: {
                        routeRow(label: "TO", tzId: destinationTZ)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var scheduleGroup: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "SCHEDULE")
                .padding(.horizontal, Spacing.xs)
            InstrumentCard(padding: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Departure")
                            .font(Typography.body(15, weight: .medium))
                            .foregroundStyle(Color.textHi)
                        Spacer()
                        DatePicker("", selection: $departure)
                            .labelsHidden()
                            .tint(Color.amber)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    Hairline()
                    HStack {
                        Text("Arrival")
                            .font(Typography.body(15, weight: .medium))
                            .foregroundStyle(Color.textHi)
                        Spacer()
                        DatePicker("", selection: $arrival, in: departure...)
                            .labelsHidden()
                            .tint(Color.amber)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
            }
        }
    }

    private var roundTripGroup: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "TRIP TYPE")
                .padding(.horizontal, Spacing.xs)
            InstrumentCard(padding: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Round trip")
                            .font(Typography.body(15, weight: .medium))
                            .foregroundStyle(Color.textHi)
                        Text("Plan the return leg too")
                            .font(Typography.mono(11))
                            .foregroundStyle(Color.textLo)
                    }
                    Spacer()
                    Toggle("", isOn: $isRoundTrip)
                        .labelsHidden()
                        .tint(Color.amber)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
            }
        }
    }

    private var returnScheduleGroup: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "RETURN")
                .padding(.horizontal, Spacing.xs)
            InstrumentCard(padding: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Departure")
                            .font(Typography.body(15, weight: .medium))
                            .foregroundStyle(Color.textHi)
                        Spacer()
                        DatePicker("", selection: $returnDeparture, in: arrival...)
                            .labelsHidden()
                            .tint(Color.amber)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    Hairline()
                    HStack {
                        Text("Arrival")
                            .font(Typography.body(15, weight: .medium))
                            .foregroundStyle(Color.textHi)
                        Spacer()
                        DatePicker("", selection: $returnArrival, in: returnDeparture...)
                            .labelsHidden()
                            .tint(Color.amber)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
            }
        }
    }

    /// Shows whether the planner will use full / partial / stay-anchored shift
    /// based on the entered round-trip duration.
    private var strategyGroup: some View {
        let trial = trialTrip
        let strategy = trial.shiftStrategy
        let days = trial.daysAtDestination ?? 0
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "STRATEGY")
                .padding(.horizontal, Spacing.xs)
            InstrumentCard {
                HStack(spacing: Spacing.md) {
                    Text(strategyCode(strategy))
                        .font(Typography.mono(13, weight: .semibold))
                        .trackedUppercase(1.4)
                        .foregroundStyle(strategyTint(strategy))
                    Text(strategyText(strategy, days: days))
                        .font(Typography.body(13))
                        .foregroundStyle(Color.textMid)
                    Spacer()
                }
            }
        }
    }

    private func strategyCode(_ s: Trip.ShiftStrategy) -> String {
        switch s {
        case .stayAnchored:        return "STAY-ANCHORED"
        case .partial(let h):
            return String(format: "PARTIAL · %.1fH", h)
        case .full:                return "FULL SHIFT"
        }
    }

    private func strategyTint(_ s: Trip.ShiftStrategy) -> Color {
        switch s {
        case .stayAnchored: return .caffeineGreen
        case .partial:      return .sleepIndigo
        case .full:         return .amber
        }
    }

    private func strategyText(_ s: Trip.ShiftStrategy, days: Int) -> String {
        switch s {
        case .stayAnchored:
            return "Short trip (\(days) day\(days == 1 ? "" : "s")) — keeping home schedule costs less than a round-trip shift."
        case .partial:
            return "Mid-length trip (\(days) days) — partial shift, not full local-aligned."
        case .full:
            return "Long trip (\(days) days) — full shift to destination, full shift back."
        }
    }

    private func directionGroup(_ preview: ShiftPreview) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionTag(text: "DIRECTION")
                .padding(.horizontal, Spacing.xs)
            InstrumentCard {
                HStack(spacing: Spacing.md) {
                    Text(preview.code)
                        .font(Typography.mono(13, weight: .semibold))
                        .trackedUppercase(1.4)
                        .foregroundStyle(preview.tint)
                    Text(preview.text)
                        .font(Typography.body(13))
                        .foregroundStyle(Color.textMid)
                    Spacer()
                }
            }
        }
    }

    // MARK: Pieces

    @ViewBuilder
    private func routeRow(label: String, tzId: String) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Text(label)
                .font(Typography.mono(11, weight: .semibold))
                .trackedUppercase(1.4)
                .foregroundStyle(Color.textLo)
                .frame(width: 48, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(cityName(tzId))
                    .font(Typography.body(15, weight: .medium))
                    .foregroundStyle(Color.textHi)
                Text(offsetLabel(tzId))
                    .font(Typography.mono(11))
                    .foregroundStyle(Color.textLo)
            }
            Spacer()
            Text("→")
                .font(Typography.mono(13, weight: .medium))
                .foregroundStyle(Color.amber)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    private struct ShiftPreview {
        let text: String
        let code: String
        let tint: Color
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
            return .init(text: "Same timezone — no jet lag protocol needed.", code: "SAME TZ", tint: .caffeineGreen)
        }
        if delta > 0 {
            return .init(text: "Eastward — body must shift \(absStr)h earlier.", code: "+\(absStr)H · ADVANCE", tint: .amber)
        }
        return .init(text: "Westward — body must shift \(absStr)h later.", code: "-\(absStr)H · DELAY", tint: .sleepIndigo)
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
        return String(format: "GMT%@%d:%02d  ·  %@", sign, mag / 3600, (mag % 3600) / 60, id)
    }

    private func hydrateFromExistingTrip() {
        guard let t = state.trip else { return }
        originTZ      = t.originTimeZoneId
        destinationTZ = t.destinationTimeZoneId
        departure     = t.departure
        arrival       = t.arrival
        if let returnDep = t.returnDeparture, let returnArr = t.returnArrival {
            isRoundTrip     = true
            returnDeparture = returnDep
            returnArrival   = returnArr
        }
    }

    private var isFormValid: Bool {
        guard originTZ != destinationTZ else { return false }
        guard arrival > departure else { return false }
        if isRoundTrip {
            guard returnDeparture > arrival, returnArrival > returnDeparture else { return false }
        }
        return true
    }

    /// Builds a Trip from current form state without committing — used by the
    /// strategy preview to compute shift mode reactively.
    private var trialTrip: Trip {
        Trip(
            id: state.trip?.id ?? UUID(),
            name: Trip.defaultName(for: originTZ, destination: destinationTZ),
            originTimeZoneId: originTZ,
            destinationTimeZoneId: destinationTZ,
            departure: departure,
            arrival: arrival,
            returnDeparture: isRoundTrip ? returnDeparture : nil,
            returnArrival:   isRoundTrip ? returnArrival   : nil
        )
    }

    private func save() {
        let trip = Trip(
            id: state.trip?.id ?? UUID(),
            name: Trip.defaultName(for: originTZ, destination: destinationTZ),
            originTimeZoneId: originTZ,
            destinationTimeZoneId: destinationTZ,
            departure: departure,
            arrival: arrival,
            returnDeparture: isRoundTrip ? returnDeparture : nil,
            returnArrival:   isRoundTrip ? returnArrival   : nil
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

    private static func defaultReturnDeparture() -> Date {
        // 7 days after the default arrival.
        Calendar.current.date(byAdding: .day, value: 7, to: defaultArrival()) ?? Date()
    }

    private static func defaultReturnArrival() -> Date {
        Calendar.current.date(byAdding: .hour, value: 10, to: defaultReturnDeparture()) ?? Date()
    }
}
