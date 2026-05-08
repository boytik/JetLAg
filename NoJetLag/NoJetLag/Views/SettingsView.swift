import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState
    @State private var bedtime: Date = Date()
    @State private var wake: Date    = Date()
    @State private var showingClearAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Sleep schedule") {
                    DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                        .onChange(of: bedtime) { newValue in
                            state.sleepSchedule.bedtimeHour = Self.decimalHour(from: newValue)
                        }
                    DatePicker("Wake up", selection: $wake, displayedComponents: .hourAndMinute)
                        .onChange(of: wake) { newValue in
                            state.sleepSchedule.wakeHour = Self.decimalHour(from: newValue)
                        }
                }

                Section("Trip") {
                    if state.trip != nil {
                        Button(role: .destructive) {
                            showingClearAlert = true
                        } label: {
                            Label("Clear current trip", systemImage: "trash")
                        }
                    } else {
                        Text("No active trip")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    disclaimer
                } header: {
                    Text("Important")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("0.1 (MVP)").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Clear trip?", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) { state.trip = nil }
            } message: {
                Text("Your sleep schedule will be kept.")
            }
            .onAppear(perform: hydrate)
        }
    }

    private var disclaimer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This app provides general guidance based on circadian-rhythm research. It is not medical advice.")
            Text("Melatonin availability and dosage rules vary by country. Consult a qualified healthcare professional before starting any supplementation.")
                .foregroundStyle(.secondary)
        }
        .font(.footnote)
    }

    private func hydrate() {
        bedtime = Self.timeFromHour(state.sleepSchedule.bedtimeHour)
        wake    = Self.timeFromHour(state.sleepSchedule.wakeHour)
    }

    private static func timeFromHour(_ hour: Double) -> Date {
        var comps = DateComponents()
        comps.hour = Int(hour)
        comps.minute = Int(((hour - Double(Int(hour))) * 60).rounded())
        return Calendar.current.date(from: comps) ?? Date()
    }

    private static func decimalHour(from date: Date) -> Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0
    }
}
