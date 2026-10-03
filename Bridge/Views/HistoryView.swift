//
//  HistoryView.swift
//  Bridge
//

import SwiftUI
import SwiftData

/// Every logged dose, grouped by day with the newest day first.
struct HistoryView: View {
    @Query(sort: \Dose.timeTaken, order: .reverse) private var doses: [Dose]

    private struct DayGroup: Identifiable {
        let day: Date
        let doses: [Dose]
        var id: Date { day }

        var averagePain: Double {
            Double(doses.reduce(0) { $0 + $1.painScore }) / Double(doses.count)
        }
    }

    /// Doses grouped by calendar day, newest day first and newest dose first
    /// within a day (the query is already sorted newest first).
    private var groups: [DayGroup] {
        let calendar = Calendar.current
        return Dictionary(grouping: doses, by: { calendar.startOfDay(for: $0.timeTaken) })
            .map { DayGroup(day: $0.key, doses: $0.value) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            Group {
                if doses.isEmpty {
                    ContentUnavailableView(
                        "No doses logged yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Doses you log on the Today tab will build up here, day by day.")
                    )
                } else {
                    List {
                        ForEach(groups) { group in
                            Section {
                                ForEach(group.doses) { dose in
                                    DoseRow(dose: dose)
                                }
                            } header: {
                                header(for: group)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private func header(for group: DayGroup) -> some View {
        HStack {
            Text(dayTitle(group.day))
            Spacer()
            Text("\(group.doses.count) \(group.doses.count == 1 ? "dose" : "doses") · avg pain \(group.averagePain.formatted(.number.precision(.fractionLength(0...1))))")
                .font(.caption)
                .textCase(nil)
        }
    }

    private func dayTitle(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [Dose.self, Plan.self], inMemory: true)
}
