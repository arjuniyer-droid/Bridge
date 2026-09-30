//
//  LogDoseSheet.swift
//  Bridge
//

import SwiftUI
import SwiftData

/// A form, presented as a sheet, for recording a single dose.
struct LogDoseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var medicationName = ""
    @State private var amount = ""
    @State private var timeTaken = Date.now
    @State private var painScore = 0
    @State private var isShowingDiscardConfirmation = false

    private var isValid: Bool {
        !medicationName.trimmingCharacters(in: .whitespaces).isEmpty
            && !amount.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Whether the person has entered anything worth not losing silently.
    private var hasUnsavedInput: Bool {
        !medicationName.trimmingCharacters(in: .whitespaces).isEmpty
            || !amount.trimmingCharacters(in: .whitespaces).isEmpty
            || painScore != 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Name", text: $medicationName)
                    TextField("Amount", text: $amount)
                }
                Section("Time") {
                    DatePicker("Time taken", selection: $timeTaken)
                }
                Section("Pain level") {
                    Stepper("Pain: \(painScore) / 10", value: $painScore, in: 0...10)
                }
            }
            .navigationTitle("Log a Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { requestDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            // Prevent a stray swipe from closing the sheet and silently
            // discarding whatever the person has already typed.
            .interactiveDismissDisabled(hasUnsavedInput)
        }
        .confirmationDialog(
            "Discard this dose?",
            isPresented: $isShowingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        }
    }

    private func requestDismiss() {
        if hasUnsavedInput {
            isShowingDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func save() {
        let dose = Dose(
            medicationName: medicationName.trimmingCharacters(in: .whitespaces),
            amount: amount.trimmingCharacters(in: .whitespaces),
            timeTaken: timeTaken,
            painScore: painScore
        )
        modelContext.insert(dose)
        dismiss()
    }
}

#Preview {
    LogDoseSheet()
        .modelContainer(for: Dose.self, inMemory: true)
}
