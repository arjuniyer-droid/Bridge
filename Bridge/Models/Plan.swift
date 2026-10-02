//
//  Plan.swift
//  Bridge
//

import Foundation
import SwiftData

/// The prescriber's plan for one medication, entered once and editable later.
@Model
final class Plan {
    static let dosesPerDayRange = 1...12

    var medicationName: String
    /// Amount for a single dose, e.g. "400mg" or "2 tablets".
    var amountPerDose: String
    var dosesPerDay: Int

    init(medicationName: String, amountPerDose: String, dosesPerDay: Int) {
        self.medicationName = medicationName
        self.amountPerDose = amountPerDose
        self.dosesPerDay = Swift.min(
            Swift.max(dosesPerDay, Self.dosesPerDayRange.lowerBound),
            Self.dosesPerDayRange.upperBound
        )
    }
}
