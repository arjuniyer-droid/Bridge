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
/// interprets it.
enum DoctorSummary {
    /// How many full days before today the summary covers.
    static let windowDays = 30

    struct Output {
        let subject: String
        let body: String
    }

    /// - Parameters:
    ///   - doses: the doses logged in the window; anything outside it is ignored.
    ///   - plans: the prescriber's plan.
    ///   - firstDoseEver: when the very first dose was logged, if any, so days
    ///     before the person started logging aren't counted as missed.
    ///   - today: the start of today. Today is left out because it isn't over.
    static func make(
        doses: [DoseRecord],
        plans: [PlanRecord],
        firstDoseEver: Date?,
        today: Date,
        calendar: Calendar = .current
    ) -> Output {
        let title = "Dose summary for my doctor"

        guard let firstDoseEver else {
            return Output(
                subject: title,
                body: """
                \(title)

                No doses have been logged in the Bridge app yet, so there is nothing to summarize.
                """
            )
        }

        let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: today)!
        let coverStart = max(windowStart, calendar.startOfDay(for: firstDoseEver))
        let days = calendar.dateComponents([.day], from: coverStart, to: today).day ?? 0

        guard days > 0 else {
            return Output(
                subject: title,
                body: """
                \(title)

                The first dose was logged today, so there are no completed days to summarize yet.
                """
            )
        }

        let lastDay = calendar.date(byAdding: .day, value: -1, to: today)!
        let dayFormat = Date.FormatStyle(calendar: calendar).month(.abbreviated).day()
        let yearFormat = Date.FormatStyle(calendar: calendar).year()
        let singleDay = coverStart == lastDay
        let period = singleDay
            ? coverStart.formatted(dayFormat)
            : "\(coverStart.formatted(dayFormat)) – \(lastDay.formatted(dayFormat))"
        let subject = "Dose summary: \(period)"

        let inWindow = doses.filter { $0.time >= coverStart && $0.time < today }
        let dosesByDay = Dictionary(grouping: inWindow) { calendar.startOfDay(for: $0.time) }
        let dayList = (0..<days).map { calendar.date(byAdding: .day, value: $0, to: coverStart)! }

        var lines: [String] = []
        lines.append(title)
        lines.append("")
        let startYear = coverStart.formatted(yearFormat)
        let endYear = lastDay.formatted(yearFormat)
        let yearText = startYear == endYear ? endYear : "\(startYear)–\(endYear)"
        lines.append("Period: \(period), \(yearText)")
        if days < windowDays {
            lines.append("(\(count(days, "day")). Logging started on \(coverStart.formatted(dayFormat)), so earlier days are not counted.)")
        } else {
            lines.append("(The last \(days) full days, not including today.)")
        }

        // MARK: Plan vs doses taken
        lines.append("")
        lines.append("DOSES TAKEN COMPARED WITH MY PLAN")
        let planTotalPerDay = plans.reduce(0) { $0 + $1.dosesPerDay }
        if plans.isEmpty {
            lines.append("No plan has been entered in the app, so there is nothing to compare against.")
            lines.append("Doses logged: \(inWindow.count).")
            let byName = Dictionary(grouping: inWindow) { $0.name.lowercased() }
            for group in byName.values.sorted(by: { $0.count > $1.count }) {
                lines.append("- \(group[0].name): \(group.count)")
            }
        } else {
            lines.append("Plan, as it is currently entered in the app:")
            for plan in plans {
                lines.append("- \(plan.name) \(plan.amount): \(plan.dosesPerDay) per day")
            }
            let expected = planTotalPerDay * days
            let planned = Set(plans.map { $0.name.lowercased() })
            let loggedByName = Dictionary(grouping: inWindow) { $0.name.lowercased() }
            let plannedTaken = planned.reduce(0) { $0 + (loggedByName[$1]?.count ?? 0) }
            lines.append("")
            lines.append("Over \(count(days, "day")) the plan adds up to \(count(expected, "dose")). Taken from the plan: \(plannedTaken) (\(percent(plannedTaken, of: expected))).")

            var seen = Set<String>()
            for plan in plans {
                let key = plan.name.lowercased()
                guard seen.insert(key).inserted else { continue }
                let perDay = plans.filter { $0.name.lowercased() == key }.reduce(0) { $0 + $1.dosesPerDay }
                let taken = loggedByName[key]?.count ?? 0
                let medExpected = perDay * days
                lines.append("- \(plan.name): \(taken) of \(medExpected) (\(percent(taken, of: medExpected)))")
            }

            let others = loggedByName
                .filter { !planned.contains($0.key) }
                .values
                .sorted { $0.count > $1.count }
            if !others.isEmpty {
                let list = others.map { "\($0[0].name) (\($0.count))" }.joined(separator: ", ")
                lines.append("Also logged, but not in my plan: \(list).")
            }

            let counts = dayList.map { dosesByDay[$0]?.count ?? 0 }
            let atLeast = counts.filter { $0 >= planTotalPerDay }.count
            let over = counts.filter { $0 > planTotalPerDay }.count
            lines.append("Days with at least the planned \(count(planTotalPerDay, "dose")): \(atLeast) of \(count(days, "day")).")
            lines.append("Days with more doses than planned: \(over).")
        }

        // MARK: Pain
        lines.append("")
        lines.append("PAIN (0 = none, 10 = worst)")
        if inWindow.isEmpty {
            lines.append("No doses were logged in this period, so there are no pain scores.")
        } else {
            let mean = Double(inWindow.reduce(0) { $0 + $1.pain }) / Double(inWindow.count)
            lines.append("Average pain score: \(number(mean)) across \(count(inWindow.count, "logged dose")).")

            let dayAverages = dayList.compactMap { day -> (Date, Double)? in
                guard let list = dosesByDay[day] else { return nil }
                return (day, Double(list.reduce(0) { $0 + $1.pain }) / Double(list.count))
            }
            if let high = dayAverages.max(by: { $0.1 < $1.1 }),
               let low = dayAverages.min(by: { $0.1 < $1.1 }),
               high.1 != low.1 {
                lines.append("Highest day: \(high.0.formatted(dayFormat)), average \(number(high.1)).")
                lines.append("Lowest day: \(low.0.formatted(dayFormat)), average \(number(low.1)).")
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
                        change = "higher"
                    } else if a - b >= 0.5 {
                        change = "lower"
                    } else {
                        change = "about the same"
                    }
                    lines.append("The second half of the period averaged \(number(b)), compared with \(number(a)) in the first half (\(change)).")
                }
            }
            lines.append("Pain was recorded when each dose was logged, so a day with no doses has no pain score.")
        }

        // MARK: Days with no doses
        lines.append("")
        lines.append("DAYS WITH NO DOSES LOGGED")
        let noDoseDays = dayList.filter { dosesByDay[$0] == nil }
        if noDoseDays.isEmpty {
            lines.append("Every day in this period has at least one dose logged.")
        } else {
            lines.append("\(noDoseDays.count) of \(count(days, "day")): \(rangeList(noDoseDays, calendar: calendar, format: dayFormat)).")
            lines.append("On these days either no dose was taken or it was not logged.")
        }

        lines.append("")
        lines.append("Made from the doses I logged in the Bridge app. It is a record of what I entered, not medical advice.")

        return Output(subject: subject, body: lines.joined(separator: "\n"))
    }

    // MARK: Formatting helpers

    private static func percent(_ part: Int, of whole: Int) -> String {
        guard whole > 0 else { return "no doses planned" }
        return "\(Int((Double(part) / Double(whole) * 100).rounded()))%"
    }

    private static func number(_ value: Double) -> String {
        let text = String(format: "%.1f", value)
        return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
    }

    /// "1 day", "30 days".
    private static func count(_ value: Int, _ word: String) -> String {
        "\(value) \(value == 1 ? word : word + "s")"
    }

    /// Joins consecutive days into ranges, such as "Sep 12, Sep 20–22, Sep 30 – Oct 2".
    private static func rangeList(_ days: [Date], calendar: Calendar, format: Date.FormatStyle) -> String {
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
            if start == end { return start.formatted(format) }
            if calendar.isDate(start, equalTo: end, toGranularity: .month) {
                return "\(start.formatted(format))–\(calendar.component(.day, from: end))"
            }
            return "\(start.formatted(format)) – \(end.formatted(format))"
        }
        .joined(separator: ", ")
    }
}
