//
//  DoseRow.swift
//  Bridge
//

import SwiftUI

/// One logged dose: medication, amount, time and pain score. Shared by the
/// Today and History lists.
struct DoseRow: View {
    let dose: Dose

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dose.medicationName)
                    .font(.headline)
                Text("\(dose.amount) · \(dose.timeTaken.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Pain \(dose.painScore)")
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.quaternary, in: Capsule())
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
        // So a tap anywhere on the row counts, not just on the text.
        .contentShape(Rectangle())
    }
}
