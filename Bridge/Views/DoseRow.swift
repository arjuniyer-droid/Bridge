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
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange.opacity(0.15), in: Capsule())
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 4)
    }
}
