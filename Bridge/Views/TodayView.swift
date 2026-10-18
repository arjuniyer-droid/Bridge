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
                TodaysDoses(
                    day: today,
                    onLog: { formTarget = DoseFormTarget(dose: nil) },
                    onSelect: { formTarget = DoseFormTarget(dose: $0) }
                )
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

/// The Log a Dose button and the doses logged on one day, newest first. With no
/// doses yet, the button moves into the empty state, so there is one clear
/// thing to do.
private struct TodaysDoses: View {
    @Query private var doses: [Dose]
    let onLog: () -> Void
    let onSelect: (Dose) -> Void

    init(day: Date, onLog: @escaping () -> Void, onSelect: @escaping (Dose) -> Void) {
        let start = day
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = #Predicate<Dose> { dose in
            dose.timeTaken >= start && dose.timeTaken < end
        }
        _doses = Query(filter: predicate, sort: \Dose.timeTaken, order: .reverse)
        self.onLog = onLog
        self.onSelect = onSelect
    }

    var body: some View {
        // The container animates when a dose is added or removed: the new row
        // settles into place and the rows around it make room.
        VStack(spacing: Space.unit) {
            if !doses.isEmpty {
                Button(action: onLog) {
                    Label("Log a Dose", systemImage: "plus")
                }
                .buttonStyle(.bridgePrimary)
            }
            content
        }
        .calmAnimation(Motion.settle, value: doses.map(\.persistentModelID))
    }

    @ViewBuilder
    private var content: some View {
        if doses.isEmpty {
            EmptyStateCard(
                systemImage: "pills",
                title: "No doses logged today",
                message: "Log a dose when you take your medication.",
                actionTitle: "Log a Dose",
                action: onLog
            )
            .transition(.opacity)
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
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.96, anchor: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .card(padded: false)
            }
            .transition(.opacity)
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Dose.self, Plan.self], inMemory: true)
}
