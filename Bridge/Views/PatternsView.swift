//
//  PatternsView.swift
//  Bridge
//

import SwiftUI
import SwiftData
import Charts

/// How far the Patterns charts reach.
private enum ChartSpan {
    /// The default window, in days.
    static let defaultDays = 14
    /// Past this many days the charts group by week, so a long history draws a
    /// few dozen bars instead of one for every day.
    static let weeklyAfterDays = 90
}

struct PatternsView: View {
    @State private var showAllHistory = false
    /// The current day, kept fresh so the 14-day window moves on at midnight.
    @State private var today = Date.startOfToday

    /// Where the loaded doses start. In the default view only the last 14 days
    /// are loaded; "all history" loads everything.
    private var since: Date? {
        showAllHistory
            ? nil
            : Calendar.current.date(byAdding: .day, value: -(ChartSpan.defaultDays - 1), to: today)!
    }

    var body: some View {
        NavigationStack {
            PatternsContent(since: since, today: today, showAllHistory: $showAllHistory)
                // A new identity per mode so the query is rebuilt cleanly.
                .id(showAllHistory)
                .navigationTitle("Patterns")
        }
        .onNewDay {
            let now = Date.startOfToday
            if now != today { today = now }
        }
    }
}

/// Whether each bar and point stands for one day or for one week.
private enum Granularity {
    case day, week

    var unit: Calendar.Component {
        self == .day ? .day : .weekOfYear
    }
}

/// What the charts need to know about one day or one week.
private struct PeriodStats: Identifiable {
    /// The start of the day, or of the week.
    let start: Date
    /// How many days of the window this period covers: 1 for a day, up to 7
    /// for a week (fewer for a partial week at either end).
    let days: Int
    let count: Int
    let painTotal: Int
    var id: Date { start }

    /// Doses per day, so a week's bar means the same thing as a day's.
    var dosesPerDay: Double { Double(count) / Double(days) }

    /// Mean pain score of the period's doses, or nil if none were taken.
    var averagePain: Double? {
        count == 0 ? nil : Double(painTotal) / Double(count)
    }
}

private struct ChartData {
    let granularity: Granularity
    let periods: [PeriodStats]
    /// The first day the charts reach.
    let rangeStart: Date

    var total: Int { periods.reduce(0) { $0 + $1.count } }
}

/// The day or week whose doses were opened by tapping its bar.
private struct PeriodSelection: Identifiable {
    let id = UUID()
    let start: Date
    /// Exclusive: the start of the next day or week.
    let end: Date
    let title: String
    let spansOneDay: Bool

    init(period: PeriodStats, granularity: Granularity) {
        let calendar = Calendar.current
        start = period.start
        spansOneDay = granularity == .day
        end = calendar.date(byAdding: .day, value: spansOneDay ? 1 : 7, to: period.start)!
        title = spansOneDay
            ? period.start.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
            : "Week of " + period.start.formatted(.dateTime.month(.abbreviated).day())
    }
}

private struct PatternsContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var doses: [Dose]
    @Query private var plans: [Plan]
    /// How many doses fall before the default 14-day window.
    @State private var olderCount = 0
    /// The tapped bar whose doses are showing, if any.
    @State private var selection: PeriodSelection?
    /// The doctor summary being shared, once it has been built.
    @State private var summaryShare: ShareContent?
    @State private var isShowingSummaryError = false

    let today: Date
    @Binding var showAllHistory: Bool

    init(since: Date?, today: Date, showAllHistory: Binding<Bool>) {
        if let since {
            let predicate = #Predicate<Dose> { dose in
                dose.timeTaken >= since
            }
            _doses = Query(filter: predicate, sort: \Dose.timeTaken)
        } else {
            _doses = Query(sort: \Dose.timeTaken)
        }
        self.today = today
        _showAllHistory = showAllHistory
    }

    /// Doses per day the prescriber's plan adds up to across all medications,
    /// or nil without a plan. The chart counts every dose of every medication,
    /// so the plan has to be totalled the same way to be comparable.
    private var prescribedPerDay: Int? {
        let total = plans.reduce(0) { $0 + $1.dosesPerDay }
        return total > 0 ? total : nil
    }

    private var defaultWindowStart: Date {
        Calendar.current.date(byAdding: .day, value: -(ChartSpan.defaultDays - 1), to: today)!
    }

    /// The last 14 days, or every day since the first logged dose when showing
    /// all history, grouped by day or, for a long span, by week. Days with no
    /// doses are kept with a count of zero so gaps are visible.
    private func chartData() -> ChartData {
        let calendar = Calendar.current
        let firstDay = doses.first.map { calendar.startOfDay(for: $0.timeTaken) }
            ?? defaultWindowStart
        let start = min(firstDay, defaultWindowStart)
        let spanDays = (calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1
        let dosesByDay = Dictionary(
            grouping: doses,
            by: { calendar.startOfDay(for: $0.timeTaken) }
        )

        if spanDays <= ChartSpan.weeklyAfterDays {
            let periods = (0..<spanDays).map { offset -> PeriodStats in
                let day = calendar.date(byAdding: .day, value: offset, to: start)!
                let dayDoses = dosesByDay[day] ?? []
                return PeriodStats(
                    start: day,
                    days: 1,
                    count: dayDoses.count,
                    painTotal: dayDoses.reduce(0) { $0 + $1.painScore }
                )
            }
            return ChartData(granularity: .day, periods: periods, rangeStart: start)
        }

        var order: [Date] = []
        var weeks: [Date: (days: Int, count: Int, pain: Int)] = [:]
        var day = start
        while day <= today {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: day)!.start
            let dayDoses = dosesByDay[day] ?? []
            if weeks[weekStart] == nil {
                order.append(weekStart)
                weeks[weekStart] = (0, 0, 0)
            }
            weeks[weekStart]!.days += 1
            weeks[weekStart]!.count += dayDoses.count
            weeks[weekStart]!.pain += dayDoses.reduce(0) { $0 + $1.painScore }
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        let periods = order.map { weekStart -> PeriodStats in
            let week = weeks[weekStart]!
            return PeriodStats(start: weekStart, days: week.days, count: week.count, painTotal: week.pain)
        }
        return ChartData(granularity: .week, periods: periods, rangeStart: start)
    }

    var body: some View {
        let data = chartData()

        Group {
            if data.total == 0 {
                ContentUnavailableView {
                    Label("No doses in the last \(ChartSpan.defaultDays) days", systemImage: "chart.bar")
                } description: {
                    Text("Log a dose on the Today tab and it will show up here.")
                } actions: {
                    // Older doses may exist even though the last 14 days are empty.
                    if olderCount > 0 {
                        Button("See all history") { showAllHistory = true }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        summaryButton
                    }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Side by side when they fit, stacked on a narrow screen.
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) {
                                historyButton
                                summaryButton
                            }
                            VStack(alignment: .leading, spacing: 12) {
                                historyButton
                                summaryButton
                            }
                        }
                        VStack(alignment: .leading, spacing: 16) {
                            dosesSummary(data)
                            DosesPerDayChart(data: data, prescribedPerDay: prescribedPerDay) { period in
                                selection = PeriodSelection(period: period, granularity: data.granularity)
                            }
                            .frame(height: 220)
                        }
                        VStack(alignment: .leading, spacing: 16) {
                            painSummary(data)
                            AveragePainChart(data: data)
                                .frame(height: 180)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear(perform: refreshOlderCount)
        .onChange(of: doses.count) { refreshOlderCount() }
        .onChange(of: today) { refreshOlderCount() }
        .sheet(item: $selection) { selection in
            PeriodDosesSheet(selection: selection)
        }
        .sheet(item: $summaryShare) { content in
            SummaryPreviewSheet(content: content)
        }
        .alert("Couldn't make the summary", isPresented: $isShowingSummaryError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your doses couldn't be read, so no summary was made. Please try again.")
        }
    }

    /// Switches the charts between the last 14 days and all history. Hidden
    /// when there is nothing older to show.
    @ViewBuilder
    private var historyButton: some View {
        if olderCount > 0 {
            Button {
                showAllHistory.toggle()
            } label: {
                Label(
                    showAllHistory ? "Show last \(ChartSpan.defaultDays) days" : "See all history",
                    systemImage: showAllHistory ? "calendar" : "clock.arrow.circlepath"
                )
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var summaryButton: some View {
        Button(action: shareDoctorSummary) {
            Label("Summary for my doctor", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    /// Reads the last 30 full days straight from the database, so the summary
    /// doesn't depend on which range the charts are showing, then shows it with
    /// a Share button. If the doses can't be read it says so rather than
    /// showing a summary that wrongly claims nothing was logged.
    private func shareDoctorSummary() {
        let calendar = Calendar.current
        let end = today
        let start = calendar.date(byAdding: .day, value: -DoctorSummary.windowDays, to: today)!

        do {
            let windowDoses = try modelContext.fetch(
                FetchDescriptor<Dose>(
                    predicate: #Predicate { $0.timeTaken >= start && $0.timeTaken < end },
                    sortBy: [SortDescriptor(\.timeTaken)]
                )
            )
            var earliest = FetchDescriptor<Dose>(sortBy: [SortDescriptor(\.timeTaken)])
            earliest.fetchLimit = 1
            let firstDoseEver = try modelContext.fetch(earliest).first?.timeTaken

            let summary = DoctorSummary.make(
                doses: windowDoses.map {
                    DoseRecord(name: $0.medicationName, amount: $0.amount, time: $0.timeTaken, pain: $0.painScore)
                },
                plans: plans.map {
                    PlanRecord(name: $0.medicationName, amount: $0.amountPerDose, dosesPerDay: $0.dosesPerDay)
                },
                firstDoseEver: firstDoseEver,
                today: today,
                calendar: calendar
            )
            summaryShare = ShareContent(text: summary.body, subject: summary.subject)
        } catch {
            isShowingSummaryError = true
        }
    }

    private func dosesSummary(_ data: ChartData) -> some View {
        let format = Date.FormatStyle().month(.abbreviated).day()
        let range = "\(data.rangeStart.formatted(format)) – \(today.formatted(format))"
        let doseWord = data.total == 1 ? "dose" : "doses"
        let summary: String
        switch data.granularity {
        case .week:
            summary = "\(data.total) \(doseWord) over \(data.periods.count) weeks"
        case .day where data.periods.count > ChartSpan.defaultDays:
            summary = "\(data.total) \(doseWord) over \(data.periods.count) days"
        case .day:
            summary = "\(data.total) \(doseWord) in the last \(ChartSpan.defaultDays) days"
        }

        return VStack(alignment: .leading, spacing: 4) {
            Text(data.granularity == .week ? "Doses per day, weekly average" : "Doses per day")
                .font(.headline)
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(range)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if data.granularity == .week {
                Text("Each bar is one week's average number of doses per day.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text("Tap a bar to see and edit that \(data.granularity == .week ? "week" : "day")'s doses.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func painSummary(_ data: ChartData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Average pain score")
                .font(.headline)
            Text(
                data.granularity == .week
                    ? "0 is no pain, 10 is the worst. Each point is a week's average, and weeks without a dose have no point."
                    : "0 is no pain, 10 is the worst. Days without a dose have no point."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    /// Counts the doses before the default window in the database without
    /// loading them, to know whether there is more history to show.
    private func refreshOlderCount() {
        let windowStart = defaultWindowStart
        let descriptor = FetchDescriptor<Dose>(
            predicate: #Predicate { $0.timeTaken < windowStart }
        )
        olderCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}

/// The x axis both charts share. For 14 days, every other day is labelled by
/// its day number, counting back from today so today is always labelled. For a
/// longer span, about six dates are labelled as month/day, kept clear of the
/// right edge where a label would be clipped.
private struct PeriodAxis: ViewModifier {
    let data: ChartData

    private var periods: [PeriodStats] { data.periods }

    private var isCompact: Bool {
        data.granularity == .day && periods.count <= ChartSpan.defaultDays
    }

    private var labelled: [Date] {
        if isCompact {
            return stride(from: periods.count - 1, through: 0, by: -2).map { periods[$0].start }
        }
        let count = periods.count
        let step = max(2, Int((Double(count) / 6).rounded(.up)))
        let lastLabelled = max(0, count - 1 - Int((Double(count) * 0.15).rounded(.up)))
        return stride(from: 0, through: lastLabelled, by: step).map { periods[$0].start }
    }

    private var labelFormat: Date.FormatStyle {
        isCompact ? Date.FormatStyle().day() : Date.FormatStyle().month(.defaultDigits).day()
    }

    private var domain: ClosedRange<Date> {
        let first = periods.first!.start
        let last = periods.last!.start
        let length = data.granularity == .day ? 1 : 7
        let end = Calendar.current.date(byAdding: .day, value: length, to: last)!
        return first...end
    }

    func body(content: Content) -> some View {
        content
            .chartXScale(domain: domain)
            .chartXAxis {
                AxisMarks(values: labelled) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: labelFormat)
                }
            }
    }
}

/// Y-axis marks on the left. The labels get a fixed width so the two charts'
/// plot areas line up even when one needs "0.25" and the other "10".
private func yAxisMarks(_ ticks: [Double]) -> some AxisContent {
    AxisMarks(position: .leading, values: ticks) { value in
        AxisGridLine()
        AxisTick()
        AxisValueLabel {
            if let tick = value.as(Double.self) {
                Text(tick, format: .number.precision(.fractionLength(0...2)))
                    .frame(width: 32, alignment: .trailing)
            }
        }
    }
}

/// A bar chart with one bar per day, or per week over a long history.
private struct DosesPerDayChart: View {
    let data: ChartData
    let prescribedPerDay: Int?
    /// Called with the day or week whose bar was tapped, if it has any doses.
    let onSelect: (PeriodStats) -> Void

    /// Number labels on the bars only fit while the bars are wide.
    private var showsValueLabels: Bool {
        data.granularity == .day && data.periods.count <= ChartSpan.defaultDays
    }

    /// Y-axis marks. A daily count is never fractional, so those marks are
    /// whole numbers; a weekly average can be, so those get decimal steps. The
    /// axis always reaches the plan's line, even when no bar gets that high.
    private var yTicks: [Double] {
        let top = max(data.periods.map(\.dosesPerDay).max() ?? 0, Double(prescribedPerDay ?? 0))
        if data.granularity == .day {
            let maxCount = Int(top.rounded(.up))
            let step = max(1, Int((Double(maxCount) / 4).rounded(.up)))
            let topTick = max(step, Int((Double(maxCount) / Double(step)).rounded(.up)) * step)
            return stride(from: 0, through: topTick, by: step).map(Double.init)
        }
        let steps = [0.25, 0.5, 1, 2, 3, 5, 10, 20]
        let step = steps.first { top / $0 <= 5 } ?? 20
        let topTick = max(step, (top / step).rounded(.up) * step)
        return stride(from: 0, through: topTick, by: step).map { $0 }
    }

    var body: some View {
        Chart(data.periods) { item in
            BarMark(
                x: .value("Period", item.start, unit: data.granularity.unit),
                y: .value("Doses per day", item.dosesPerDay)
            )
            .foregroundStyle(.tint)
            .annotation(position: .top, spacing: 2) {
                // The count on each bar, only while there are few enough bars for
                // the numbers to stay readable, and not on empty days.
                if showsValueLabels && item.count > 0 {
                    Text("\(item.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }

            if let prescribedPerDay {
                RuleMark(y: .value("Prescribed", prescribedPerDay))
                    .foregroundStyle(.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .annotation(position: .top, alignment: .leading, spacing: 2) {
                        Text("Plan: \(prescribedPerDay) per day")
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                    }
            }
        }
        .chartYScale(domain: 0...(yTicks.last ?? 1))
        .chartYAxis { yAxisMarks(yTicks) }
        .chartYAxisLabel(data.granularity == .week ? "Doses per day (weekly avg)" : "Doses", position: .leading)
        .chartXAxisLabel(position: .bottom, alignment: .center) { Text(data.granularity == .week ? "Week of" : "Day of month") }
        .modifier(PeriodAxis(data: data))
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let plotFrame = proxy.plotFrame else { return }
                        let x = location.x - geometry[plotFrame].origin.x
                        guard let date = proxy.value(atX: x, as: Date.self) else { return }
                        // The bar the tap landed in is the last one starting at or before it.
                        if let period = data.periods.last(where: { $0.start <= date }), period.count > 0 {
                            onSelect(period)
                        }
                    }
            }
        }
    }
}

/// The doses of one tapped day or week, each opening the edit form.
private struct PeriodDosesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var doses: [Dose]
    @State private var formTarget: DoseFormTarget?

    let selection: PeriodSelection

    init(selection: PeriodSelection) {
        let start = selection.start
        let end = selection.end
        let predicate = #Predicate<Dose> { dose in
            dose.timeTaken >= start && dose.timeTaken < end
        }
        _doses = Query(filter: predicate, sort: \Dose.timeTaken, order: .reverse)
        self.selection = selection
    }

    private struct DayGroup: Identifiable {
        let day: Date
        let doses: [Dose]
        var id: Date { day }
    }

    /// The period's doses by calendar day, newest day first.
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
                        "No doses",
                        systemImage: "pills",
                        description: Text("Nothing is logged for this period.")
                    )
                } else {
                    List {
                        ForEach(groups) { group in
                            Section {
                                ForEach(group.doses) { dose in
                                    Button {
                                        formTarget = DoseFormTarget(dose: dose)
                                    } label: {
                                        DoseRow(dose: dose)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint("Edit this dose")
                                }
                            } header: {
                                // A single day's title is already in the navigation bar.
                                if !selection.spansOneDay {
                                    Text(group.day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(selection.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $formTarget) { target in
                DoseFormSheet(dose: target.dose)
            }
        }
        .disclaimerFooter()
        .presentationDetents([.medium, .large])
    }
}

/// A line of each day's, or each week's, average pain score. Periods without a
/// dose have no point, and the line breaks there rather than dipping to zero
/// or joining across.
private struct AveragePainChart: View {
    let data: ChartData

    /// Dots on each period are only useful over a short span; over a long one
    /// they pile up, so the line stands alone.
    private var showsPoints: Bool { data.periods.count <= 31 }

    /// Number labels on the dots only fit in the short 14-day view.
    private var showsValueLabels: Bool {
        data.granularity == .day && data.periods.count <= ChartSpan.defaultDays
    }

    /// Periods that have a score, each tagged with which unbroken run of
    /// consecutive such periods it belongs to, so a gap splits the line.
    private var points: [(stats: PeriodStats, run: Int)] {
        var run = 0
        var previousHadScore = false
        var result: [(PeriodStats, Int)] = []
        for stats in data.periods {
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
        Chart(points, id: \.stats.start) { point in
            if let pain = point.stats.averagePain {
                LineMark(
                    x: .value("Period", point.stats.start, unit: data.granularity.unit),
                    y: .value("Average pain", pain),
                    series: .value("Run", point.run)
                )
                .foregroundStyle(.tint)
                .interpolationMethod(.monotone)

                if showsPoints {
                    PointMark(
                        x: .value("Period", point.stats.start, unit: data.granularity.unit),
                        y: .value("Average pain", pain)
                    )
                    .foregroundStyle(.tint)
                    .annotation(position: .top, spacing: 2) {
                        // The score above each dot, only for the short 14-day view.
                        if showsValueLabels {
                            Text(pain, format: .number.precision(.fractionLength(0...1)))
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .chartYScale(domain: 0...10)
        .chartYAxis { yAxisMarks([0, 2, 4, 6, 8, 10]) }
        .chartYAxisLabel(data.granularity == .week ? "Pain (weekly avg, 0–10)" : "Pain (0–10)", position: .leading)
        .chartXAxisLabel(position: .bottom, alignment: .center) { Text(data.granularity == .week ? "Week of" : "Day of month") }
        .modifier(PeriodAxis(data: data))
    }
}

#Preview {
    PatternsView()
        .modelContainer(for: [Dose.self, Plan.self], inMemory: true)
}
