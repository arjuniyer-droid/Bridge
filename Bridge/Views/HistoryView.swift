//
//  HistoryView.swift
//  Bridge
//

import SwiftUI
import SwiftData

/// Every logged dose, grouped by day with the newest day first. Only the most
/// recent stretch is loaded; older doses are fetched when asked for, so the
/// work this screen does stays the same size however long the history grows.
struct HistoryView: View {
    /// How many days each "Show older doses" tap reveals at least.
    private static let pageDays = 60

    @State private var formTarget: DoseFormTarget?
    /// The current day, kept fresh so the "Today" and "Yesterday" headings
    /// move on at midnight instead of labelling the wrong days.
    @State private var today = Date.startOfToday
    /// How many days back the list reaches, counting today.
    @State private var windowDays = HistoryView.pageDays

    /// The start of the earliest day the list currently reaches.
    private var cutoff: Date {
        Calendar.current.date(byAdding: .day, value: -(windowDays - 1), to: today)!
    }

    var body: some View {
        NavigationStack {
            HistoryList(
                cutoff: cutoff,
                today: today,
                onSelect: { formTarget = DoseFormTarget(dose: $0) },
                onShowOlder: showOlder(reaching:)
            )
            .navigationTitle("History")
            .sheet(item: $formTarget) { target in
                DoseFormSheet(dose: target.dose)
            }
        }
        .onNewDay {
            let now = Date.startOfToday
            if now != today { today = now }
        }
    }

    /// Reaches back far enough to include the newest dose that is still hidden,
    /// plus another page beyond it, so every tap reveals something even across
    /// a long gap with nothing logged.
    private func showOlder(reaching date: Date) {
        let calendar = Calendar.current
        let daysBack = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: today
        ).day ?? 0
        windowDays = max(windowDays + Self.pageDays, daysBack + Self.pageDays)
    }
}

/// The doses from `cutoff` onward, grouped by day, with a button to reach
/// further back when older doses exist.
private struct HistoryList: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var doses: [Dose]
    /// How many doses sit before `cutoff` and so are not loaded.
    @State private var olderCount = 0

    let cutoff: Date
    let today: Date
    let onSelect: (Dose) -> Void
    let onShowOlder: (Date) -> Void

    init(
        cutoff: Date,
        today: Date,
        onSelect: @escaping (Dose) -> Void,
        onShowOlder: @escaping (Date) -> Void
    ) {
        let predicate = #Predicate<Dose> { dose in
            dose.timeTaken >= cutoff
        }
        _doses = Query(filter: predicate, sort: \Dose.timeTaken, order: .reverse)
        self.cutoff = cutoff
        self.today = today
        self.onSelect = onSelect
        self.onShowOlder = onShowOlder
    }

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
        Group {
            if doses.isEmpty && olderCount == 0 {
                ContentUnavailableView(
                    "No doses logged yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Doses you log on the Today tab will build up here, day by day.")
                )
            } else {
                List {
                    if doses.isEmpty {
                        Section {
                            Text("No doses in this stretch.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    ForEach(groups) { group in
                        Section {
                            ForEach(group.doses) { dose in
                                Button {
                                    onSelect(dose)
                                } label: {
                                    DoseRow(dose: dose)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Edit this dose")
                            }
                        } header: {
                            header(for: group)
                        }
                    }
                    if olderCount > 0 {
                        Section {
                            Button(action: showOlder) {
                                Label("Show older doses", systemImage: "clock.arrow.circlepath")
                            }
                        } footer: {
                            Text("\(olderCount) older \(olderCount == 1 ? "dose" : "doses") not shown")
                        }
                    }
                }
            }
        }
        .onAppear(perform: refreshOlderCount)
        .onChange(of: doses.count) { refreshOlderCount() }
        .onChange(of: cutoff) { refreshOlderCount() }
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
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        if calendar.isDate(day, inSameDayAs: today) { return "Today" }
        if calendar.isDate(day, inSameDayAs: yesterday) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    /// Counts the hidden doses in the database without loading them.
    private func refreshOlderCount() {
        let cutoff = self.cutoff
        let descriptor = FetchDescriptor<Dose>(
            predicate: #Predicate { $0.timeTaken < cutoff }
        )
        olderCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Finds the newest hidden dose and asks the screen to reach back to it.
    private func showOlder() {
        let cutoff = self.cutoff
        var descriptor = FetchDescriptor<Dose>(
            predicate: #Predicate { $0.timeTaken < cutoff },
            sortBy: [SortDescriptor(\.timeTaken, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        if let newest = try? modelContext.fetch(descriptor).first {
            onShowOlder(newest.timeTaken)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [Dose.self, Plan.self], inMemory: true)
}
