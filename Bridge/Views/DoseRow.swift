//
//  DoseRow.swift
//  Bridge
//

import SwiftUI

/// One logged dose: medication, amount, time and pain score. Shared by the
/// Today list and the day and week sheets. It pads itself, so it belongs in a
/// card made with `DividedStack` and `card(padded: false)`.
struct DoseRow: View {
    let dose: Dose

    var body: some View {
        HStack(spacing: Space.unit) {
            VStack(alignment: .leading, spacing: Space.tight) {
                Text(dose.medicationName)
                    .font(.bridge(.headline))
                    .foregroundStyle(Color.textPrimary)
                Text("\(dose.amount) · \(dose.timeTaken, format: Date.FormatStyle(date: .omitted, time: .shortened))")
                    .font(.bridge(.secondary))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: Space.half)
            Text("Pain \(dose.painScore)")
                .font(.bridge(.captionStrong))
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, Space.half)
                .padding(.vertical, Space.tight)
                .background(.quaternary, in: Capsule())
        }
        .cardRow()
        // So a tap anywhere on the row counts, not just on the text.
        .contentShape(Rectangle())
    }
}
