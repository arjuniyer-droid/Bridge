//
//  DoctorSummary.swift
//  Bridge
//

import Foundation

/// A logged dose, reduced to what the summary needs.
struct DoseRecord {
    let name: String
    let amount: String
    let time: Date
    let pain: Int
}

/// One medication from the prescriber's plan.
struct PlanRecord {
    let name: String
    let amount: String
    let dosesPerDay: Int
}

/// Builds the plain-language summary of the last 30 full days that the person
/// can hand to their doctor. It only reports what was logged and never
/// interprets it. It is written in the language the app is showing, so the
/// person can share it in the language they read.
enum DoctorSummary {
    /// How many full days before today the summary covers.
    static let windowDays = 30

    struct Output {
        let subject: String
        let body: String
        /// The indexes of the body's lines that are section headings.
        let headings: Set<Int>
    }

    /// - Parameters:
    ///   - doses: the doses logged in the window; anything outside it is ignored.
    ///   - plans: the prescriber's plan.
    ///   - firstDoseEver: when the very first dose was logged, if any, so days
    ///     before the person started logging aren't counted as missed.
    ///   - today: the start of today. Today is left out because it isn't over.
    ///   - lang: the language to write it in.
    static func make(
        doses: [DoseRecord],
        plans: [PlanRecord],
        firstDoseEver: Date?,
        today: Date,
        calendar: Calendar = .current,
        lang: Lang
    ) -> Output {
        let title = lang("Dose summary for my doctor")

        // These words have plural forms, which differ by language, so each is a
        // whole phrase in the string catalog rather than a word with an "s".
        func dayCount(_ value: Int) -> String { lang("\(value) days") }
        func doseCount(_ value: Int) -> String { lang("\(value) doses") }
        func loggedDoseCount(_ value: Int) -> String { lang("\(value) logged doses") }
        func percent(_ part: Int, of whole: Int) -> String {
            guard whole > 0 else { return lang("no doses planned") }
            return "\(Int((Double(part) / Double(whole) * 100).rounded()))%"
        }
        /// One decimal place, none when it would be zero, with the language's separator.
        func number(_ value: Double) -> String {
            value.formatted(.number.precision(.fractionLength(0...1)).locale(lang.locale))
        }

        guard let firstDoseEver else {
            return Output(
                subject: title,
                body: title + "\n\n" + lang("No doses have been logged in the Bridge app yet, so there is nothing to summarize."),
                headings: []
            )
        }

        let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: today)!
        let coverStart = max(windowStart, calendar.startOfDay(for: firstDoseEver))
        let days = calendar.dateComponents([.day], from: coverStart, to: today).day ?? 0

        guard days > 0 else {
            return Output(
                subject: title,
                body: title + "\n\n" + lang("The first dose was logged today, so there are no completed days to summarize yet."),
                headings: []
            )
        }

        let lastDay = calendar.date(byAdding: .day, value: -1, to: today)!
        let dayFormat = Date.FormatStyle(locale: lang.locale, calendar: calendar).month(.abbreviated).day()
        let yearFormat = Date.FormatStyle(locale: lang.locale, calendar: calendar).year()
        let intervalFormat = Date.IntervalFormatStyle(locale: lang.locale, calendar: calendar).month(.abbreviated).day()
        let singleDay = coverStart == lastDay
        let period = singleDay
            ? coverStart.formatted(dayFormat)
            : (coverStart..<lastDay).formatted(intervalFormat)
        let subject = lang("Dose summary: \(period)")

        let inWindow = doses.filter { $0.time >= coverStart && $0.time < today }
        let dosesByDay = Dictionary(grouping: inWindow) { calendar.startOfDay(for: $0.time) }
        let dayList = (0..<days).map { calendar.date(byAdding: .day, value: $0, to: coverStart)! }

        var lines: [String] = []
        var headings = Set<Int>()
        /// Adds a section heading, after the blank line that separates sections.
        func addHeading(_ text: String) {
            lines.append("")
            headings.insert(lines.count)
            lines.append(text)
        }
        lines.append(title)
        lines.append("")
        let startYear = coverStart.formatted(yearFormat)
        let endYear = lastDay.formatted(yearFormat)
        let yearText = startYear == endYear ? endYear : "\(startYear)–\(endYear)"
        lines.append(lang("Period: \(period), \(yearText)"))
        if days < windowDays {
            lines.append(lang("(\(dayCount(days)). Logging started on \(coverStart.formatted(dayFormat)), so earlier days are not counted.)"))
        } else {
            lines.append(lang("(The last \(days) full days, not including today.)"))
        }

        // MARK: Plan vs doses taken
        addHeading(lang("DOSES TAKEN COMPARED WITH MY PLAN"))
        let planTotalPerDay = plans.reduce(0) { $0 + $1.dosesPerDay }
        if plans.isEmpty {
            lines.append(lang("No plan has been entered in the app, so there is nothing to compare against."))
            lines.append(lang("Doses logged: \(inWindow.count)."))
            let byName = Dictionary(grouping: inWindow) { $0.name.lowercased() }
            for group in byName.values.sorted(by: { $0.count > $1.count }) {
                lines.append("- \(group[0].name): \(group.count)")
            }
        } else {
            lines.append(lang("Plan, as it is currently entered in the app:"))
            for plan in plans {
                lines.append(lang("- \(plan.name) \(plan.amount): \(plan.dosesPerDay) per day"))
            }
            let expected = planTotalPerDay * days
            let planned = Set(plans.map { $0.name.lowercased() })
            let loggedByName = Dictionary(grouping: inWindow) { $0.name.lowercased() }
            let plannedTaken = planned.reduce(0) { $0 + (loggedByName[$1]?.count ?? 0) }
            lines.append("")
            lines.append(lang("Over \(dayCount(days)) the plan adds up to \(doseCount(expected)). Taken from the plan: \(plannedTaken) (\(percent(plannedTaken, of: expected)))."))

            var seen = Set<String>()
            for plan in plans {
                let key = plan.name.lowercased()
                guard seen.insert(key).inserted else { continue }
                let perDay = plans.filter { $0.name.lowercased() == key }.reduce(0) { $0 + $1.dosesPerDay }
                let taken = loggedByName[key]?.count ?? 0
                let medExpected = perDay * days
                lines.append(lang("- \(plan.name): \(taken) of \(medExpected) (\(percent(taken, of: medExpected)))"))
            }

            let others = loggedByName
                .filter { !planned.contains($0.key) }
                .values
                .sorted { $0.count > $1.count }
            if !others.isEmpty {
                let list = others.map { "\($0[0].name) (\($0.count))" }.joined(separator: ", ")
                lines.append(lang("Also logged, but not in my plan: \(list)."))
            }

            let counts = dayList.map { dosesByDay[$0]?.count ?? 0 }
            let atLeast = counts.filter { $0 >= planTotalPerDay }.count
            let over = counts.filter { $0 > planTotalPerDay }.count
            lines.append(lang("Days with at least the planned \(doseCount(planTotalPerDay)): \(atLeast) of \(dayCount(days))."))
            lines.append(lang("Days with more doses than planned: \(over)."))
        }

        // MARK: Pain
        addHeading(lang("PAIN (0 = none, 10 = worst)"))
        if inWindow.isEmpty {
            lines.append(lang("No doses were logged in this period, so there are no pain scores."))
        } else {
            let mean = Double(inWindow.reduce(0) { $0 + $1.pain }) / Double(inWindow.count)
            lines.append(lang("Average pain score: \(number(mean)) across \(loggedDoseCount(inWindow.count))."))

            let dayAverages = dayList.compactMap { day -> (Date, Double)? in
                guard let list = dosesByDay[day] else { return nil }
                return (day, Double(list.reduce(0) { $0 + $1.pain }) / Double(list.count))
            }
            if let high = dayAverages.max(by: { $0.1 < $1.1 }),
               let low = dayAverages.min(by: { $0.1 < $1.1 }),
               high.1 != low.1 {
                lines.append(lang("Highest day: \(high.0.formatted(dayFormat)), average \(number(high.1))."))
                lines.append(lang("Lowest day: \(low.0.formatted(dayFormat)), average \(number(low.1))."))
            }

            if days >= 14 {
                let splitDay = calendar.date(byAdding: .day, value: days / 2, to: coverStart)!
                let firstHalf = inWindow.filter { $0.time < splitDay }
                let secondHalf = inWindow.filter { $0.time >= splitDay }
                if firstHalf.count >= 3 && secondHalf.count >= 3 {
                    let a = Double(firstHalf.reduce(0) { $0 + $1.pain }) / Double(firstHalf.count)
                    let b = Double(secondHalf.reduce(0) { $0 + $1.pain }) / Double(secondHalf.count)
                    let change: String
                    if b - a >= 0.5 {
                        change = lang("higher")
                    } else if a - b >= 0.5 {
                        change = lang("lower")
                    } else {
                        change = lang("about the same")
                    }
                    lines.append(lang("The second half of the period averaged \(number(b)), compared with \(number(a)) in the first half (\(change))."))
                }
            }
            lines.append(lang("Pain was recorded when each dose was logged, so a day with no doses has no pain score."))
        }

        // MARK: Days with no doses
        addHeading(lang("DAYS WITH NO DOSES LOGGED"))
        let noDoseDays = dayList.filter { dosesByDay[$0] == nil }
        if noDoseDays.isEmpty {
            lines.append(lang("Every day in this period has at least one dose logged."))
        } else {
            let list = rangeList(noDoseDays, calendar: calendar, format: intervalFormat, single: dayFormat)
            lines.append(lang("\(noDoseDays.count) of \(dayCount(days)): \(list)."))
            lines.append(lang("On these days either no dose was taken or it was not logged."))
        }

        lines.append("")
        lines.append(lang("Made from the doses I logged in the Bridge app. It is a record of what I entered, not medical advice."))

        return Output(subject: subject, body: lines.joined(separator: "\n"), headings: headings)
    }

    // MARK: Formatting helpers

    /// Joins consecutive days into ranges, such as "Sep 12, Sep 20 – 22, Sep 30 – Oct 2",
    /// written the way the language writes date ranges.
    private static func rangeList(
        _ days: [Date],
        calendar: Calendar,
        format: Date.IntervalFormatStyle,
        single: Date.FormatStyle
    ) -> String {
        var ranges: [(Date, Date)] = []
        for day in days.sorted() {
            if let last = ranges.last,
               calendar.date(byAdding: .day, value: 1, to: last.1) == day {
                ranges[ranges.count - 1].1 = day
            } else {
                ranges.append((day, day))
            }
        }
        return ranges.map { start, end in
            start == end ? start.formatted(single) : (start..<end).formatted(format)
        }
        .joined(separator: ", ")
    }
}
