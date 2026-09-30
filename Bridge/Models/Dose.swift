//
//  Dose.swift
//  Bridge
//

import Foundation
import SwiftData

@Model
final class Dose {
    var medicationName: String
    var amount: String
    var timeTaken: Date
    /// Pain score reported at the time of this dose, from 0 (no pain) to 10 (worst pain).
    var painScore: Int

    init(
        medicationName: String,
        amount: String,
        timeTaken: Date = .now,
        painScore: Int
    ) {
        self.medicationName = medicationName
        self.amount = amount
        self.timeTaken = timeTaken
        self.painScore = painScore.clamped(to: 0...10)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
