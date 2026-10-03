//
//  TodayView.swift
//  Bridge
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var todaysDoses: [Dose]
    /// What the dose sheet is showing: a new dose (nil dose) or a logged one.
    @State private var formTarget: DoseFormTarget?

    init() {
        let startOfToday = Calendar.current.startOfDay(for: .now)
        let startOfTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
        let predicate = #Predicate<Dose> { dose in
            dose.timeTaken >= startOfToday && dose.timeTaken < startOfTomorrow
        }
        _todaysDoses = Query(filter: predicate, sort: \Dose.timeTaken, order: .reverse)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Button {
                    formTarget = DoseFormTarget(dose: nil)
                } label: {
                    Label("Log a Dose", systemImage: "plus.circle.fill")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.top, 8)

                if todaysDoses.isEmpty {
                    ContentUnavailableView(
                        "No doses logged today",
                        systemImage: "pills",
                        description: Text("Doses you log today will show up here.")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List(todaysDoses) { dose in
                        Button {
                            formTarget = DoseFormTarget(dose: dose)
                        } label: {
                            DoseRow(dose: dose)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Edit this dose")
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Today")
            .sheet(item: $formTarget) { target in
                DoseFormSheet(dose: target.dose)
            }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Dose.self, Plan.self], inMemory: true)
}
