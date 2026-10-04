//
//  PatternsView.swift
//  Bridge
//

import SwiftUI
import SwiftData
import Charts

struct PatternsView: View {
    private static let dayCount = 14

    @Query(sort: \Dose.timeTaken) private var doses: [Dose]
    @Query private var plans: [Plan]

    /// Whether the charts reach back to the first logged dose instead of 14 days.
    @State private var showAllHistory = false
    /// The current day, kept fresh so the 14-day window moves on at midnight.
    @State private var today = Date.startOfToday

    /// True when something was logged before the last 14 days, so there is
    /// more history than the default charts show.
    private var hasOlderHistory: Bool {
        guard let first = doses.first else { return false }
        let calendar = Calendar.current
        let windowStart = calendar.date(
            byAdding: .day,
            value: -(Self.dayCount - 1),
            to: today
        )!
        return calendar.startOfDay(for: first.timeTaken) < windowStart
    }

    /// Doses per day the prescriber's plan adds up to across all medications,
    /// or nil without a plan. The chart counts every dose of every medication,
    /// so the plan has to be totalled the same way to be comparable.
    private var prescribedPerDay: Int? {
        let total = plans.reduce(0) { $0 + $1.dosesPerDay }
        return total > 0 ? total : nil
    }

    /// The last 14 days, or every day since the first logged dose when showing
    /// all history. Oldest first and ending today. Days with no doses are
    /// included with a count of zero and no pain score so gaps are visible.
    private var dayStats: [DayStats] {
        let calendar = Calendar.current
        let dosesByDay = Dictionary(
            grouping: doses,
            by: { calendar.startOfDay(for: $0.timeTaken) }
        )

        var spanDays = Self.dayCount
        if showAllHistory, let first = doses.first {
            let firstDay = calendar.startOfDay(for: first.timeTaken)
            let sinceFirst = calendar.dateComponents([.day], from: firstDay, to: today).day ?? 0
            spanDays = max(Self.dayCount, sinceFirst + 1)
        }

        return (0..<spanDays).reversed().map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayDoses = dosesByDay[day] ?? []
            let averagePain = dayDoses.isEmpty
                ? nil
                : Double(dayDoses.reduce(0) { $0 + $1.painScore }) / Double(dayDoses.count)
            return DayStats(day: day, count: dayDoses.count, averagePain: averagePain)
        }
    }

    var body: some View {
        let days = dayStats
        let total = days.reduce(0) { $0 + $1.count }

        NavigationStack {
            Group {
                if total == 0 {
                    ContentUnavailableView {
                        Label("No doses in the last 14 days", systemImage: "chart.bar")
                    } description: {
                        Text("Log a dose on the Today tab and it will show up here.")
                    } actions: {
                        // Older doses may exist even though the last 14 days are empty.
                        if hasOlderHistory {
                            Button("See all history") { showAllHistory = true }
                                .buttonStyle(.bordered)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if hasOlderHistory {
                                Button {
                                    showAllHistory.toggle()
                                } label: {
                                    Label(
                                        showAllHistory ? "Show last \(Self.dayCount) days" : "See all history",
                                        systemImage: showAllHistory ? "calendar" : "clock.arrow.circlepath"
                                    )
                                }
                                .buttonStyle(.bordered)
                            }
                            VStack(alignment: .leading, spacing: 16) {
                                dosesSummary(total: total, days: days)
                                DosesPerDayChart(days: days, prescribedPerDay: prescribedPerDay)
                                    .frame(height: 220)
                            }
                            VStack(alignment: .leading, spacing: 16) {
                                painSummary
                                AveragePainChart(days: days, showsPoints: days.count <= 31)
                                    .frame(height: 180)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Patterns")
        }
        .onNewDay {
            let now = Date.startOfToday
            if now != today { today = now }
        }
    }

    private func dosesSummary(total: Int, days: [DayStats]) -> some View {
        let format = Date.FormatStyle().month(.abbreviated).day()
        let range = "\(days.first!.day.formatted(format)) – \(days.last!.day.formatted(format))"

        return VStack(alignment: .leading, spacing: 4) {
            Text("Doses per day")
                .font(.headline)
            Text(
                days.count > Self.dayCount
                    ? "\(total) \(total == 1 ? "dose" : "doses") over \(days.count) days"
                    : "\(total) \(total == 1 ? "dose" : "doses") in the last \(Self.dayCount) days"
            )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(range)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var painSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Average pain score")
                .font(.headline)
            Text("0 is no pain, 10 is the worst. Days without a dose have no point.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

/// What the charts need to know about one calendar day.
private struct DayStats: Identifiable {
    let day: Date
    let count: Int
    /// Mean pain score of the day's doses, or nil if none were taken.
    let averagePain: Double?
    var id: Date { day }
}

/// The x axis both charts share. For 14 days, every other day is labelled by
/// its day number, counting back from today so today is always labelled. For a
/// longer span, about six dates are labelled as month/day, kept clear of the
/// right edge where a label would be clipped.
private struct DayAxis: ViewModifier {
    let days: [DayStats]

    private var isCompact: Bool { days.count <= 14 }

    private var labelledDays: [Date] {
        if isCompact {
            return stride(from: days.count - 1, through: 0, by: -2).map { days[$0].day }
        }
        let count = days.count
        let step = max(2, Int((Double(count) / 6).rounded(.up)))
        let lastLabelled = max(0, count - 1 - Int((Double(count) * 0.15).rounded(.up)))
        return stride(from: 0, through: lastLabelled, by: step).map { days[$0].day }
    }

    private var labelFormat: Date.FormatStyle {
        isCompact ? Date.FormatStyle().day() : Date.FormatStyle().month(.defaultDigits).day()
    }

    private var domain: ClosedRange<Date> {
        let first = days.first!.day
        let end = Calendar.current.date(byAdding: .day, value: 1, to: days.last!.day)!
        return first...end
    }

    func body(content: Content) -> some View {
        content
            .chartXScale(domain: domain)
            .chartXAxis {
                AxisMarks(values: labelledDays) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: labelFormat)
                }
            }
    }
}

/// Whole-number y-axis marks on the left. The labels get a fixed width so the
/// two charts' plot areas line up even when one needs "10" and the other "3".
private func yAxisMarks(_ ticks: [Int]) -> some AxisContent {
    AxisMarks(position: .leading, values: ticks) { value in
        AxisGridLine()
        AxisTick()
        AxisValueLabel {
            if let tick = value.as(Int.self) {
                Text("\(tick)")
                    .frame(width: 22, alignment: .trailing)
            }
        }
    }
}

/// A bar chart with one bar per day.
private struct DosesPerDayChart: View {
    let days: [DayStats]
    let prescribedPerDay: Int?

    /// Y-axis marks as whole numbers: a count of doses is never fractional.
    /// The axis always reaches the plan's line, even when no day gets that high.
    private var yTicks: [Int] {
        let maxCount = max(days.map(\.count).max() ?? 0, prescribedPerDay ?? 0)
        let step = max(1, Int((Double(maxCount) / 4).rounded(.up)))
        let top = max(step, Int((Double(maxCount) / Double(step)).rounded(.up)) * step)
        return Array(stride(from: 0, through: top, by: step))
    }

    var body: some View {
        Chart(days) { item in
            BarMark(
                x: .value("Day", item.day, unit: .day),
                y: .value("Doses", item.count)
            )
            .foregroundStyle(.tint)

            if let prescribedPerDay {
                RuleMark(y: .value("Prescribed", prescribedPerDay))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .annotation(position: .top, alignment: .leading, spacing: 2) {
                        Text("Plan: \(prescribedPerDay) per day")
                            .font(.caption2.bold())
                            .foregroundStyle(.orange)
                    }
            }
        }
        .chartYScale(domain: 0...(yTicks.last ?? 1))
        .chartYAxis { yAxisMarks(yTicks) }
        .modifier(DayAxis(days: days))
    }
}

/// A line of each day's average pain score. Days without a dose have no point,
/// and the line breaks there rather than dipping to zero or joining across.
private struct AveragePainChart: View {
    let days: [DayStats]
    /// Dots on each day are only useful over a short span; over a long one they
    /// pile up, so the line stands alone.
    let showsPoints: Bool

    /// Days that have a score, each tagged with which unbroken run of
    /// consecutive such days it belongs to, so a gap splits the line.
    private var points: [(stats: DayStats, run: Int)] {
        var run = 0
        var previousHadScore = false
        var result: [(DayStats, Int)] = []
        for stats in days {
            if stats.averagePain != nil {
                if !previousHadScore { run += 1 }
                result.append((stats, run))
                previousHadScore = true
            } else {
                previousHadScore = false
            }
        }
        return result
    }

    var body: some View {
        Chart(points, id: \.stats.day) { point in
            if let pain = point.stats.averagePain {
                LineMark(
                    x: .value("Day", point.stats.day, unit: .day),
                    y: .value("Average pain", pain),
                    series: .value("Run", point.run)
                )
                .foregroundStyle(.red)
                .interpolationMethod(.monotone)

                if showsPoints {
                    PointMark(
                        x: .value("Day", point.stats.day, unit: .day),
                        y: .value("Average pain", pain)
                    )
                    .foregroundStyle(.red)
                }
            }
        }
        .chartYScale(domain: 0...10)
        .chartYAxis { yAxisMarks([0, 2, 4, 6, 8, 10]) }
        .modifier(DayAxis(days: days))
    }
}

#Preview {
    PatternsView()
        .modelContainer(for: [Dose.self, Plan.self], inMemory: true)
}
