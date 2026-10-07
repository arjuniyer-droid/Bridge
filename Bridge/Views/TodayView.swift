//
//  TodayView.swift
//  Bridge
//

import SwiftUI
import SwiftData

struct TodayView: View {
    /// The day the list is showing. It moves forward when the day rolls over so
    /// the list never keeps showing yesterday as "today".
    @State private var today = Date.startOfToday
    /// What the dose sheet is showing: a new dose (nil dose) or a logged one.
    @State private var formTarget: DoseFormTarget?

    var body: some View {
        NavigationStack {
            Screen(footer: true) {
                Button {
                    formTarget = DoseFormTarget(dose: nil)
                } label: {
                    Label("Log a Dose", systemImage: "plus")
                }
                .buttonStyle(.bridgePrimary)

                TodaysDoses(day: today) { dose in
                    formTarget = DoseFormTarget(dose: dose)
                }
                // A new identity per day makes the list rebuild its query.
                .id(today)
            }
            .navigationTitle("Today")
            .sheet(item: $formTarget) { target in
                DoseFormSheet(dose: target.dose)
            }
        }
        .onNewDay {
            let now = Date.startOfToday
            if now != today { today = now }
        }
    }
}

/// The doses logged on one day, newest first, or an empty state.
private struct TodaysDoses: View {
    @Query private var doses: [Dose]
    let onSelect: (Dose) -> Void

    init(day: Date, onSelect: @escaping (Dose) -> Void) {
        let start = day
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = #Predicate<Dose> { dose in
            dose.timeTaken >= start && dose.timeTaken < end
        }
        _doses = Query(filter: predicate, sort: \Dose.timeTaken, order: .reverse)
        self.onSelect = onSelect
    }

    var body: some View {
        if doses.isEmpty {
            EmptyStateCard(
                systemImage: "pills",
                title: "No doses logged today",
                message: "Doses you log today will show up here."
            )
        } else {
            VStack(alignment: .leading, spacing: Space.half) {
                SectionTitle("Logged today")
                DividedStack {
                    ForEach(doses) { dose in
                        Button {
                            onSelect(dose)
                        } label: {
                            DoseRow(dose: dose)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Edit this dose")
                    }
                }
                .card(padded: false)
            }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Dose.self, Plan.self], inMemory: true)
}
