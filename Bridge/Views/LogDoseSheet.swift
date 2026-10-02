//
//  LogDoseSheet.swift
//  Bridge
//

import SwiftUI
import SwiftData

/// A form, presented as a sheet, for recording a single dose. Tapping the name
/// or amount field offers what's in the person's plan; typing a different
/// value still works.
struct LogDoseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Plan.medicationName) private var plans: [Plan]

    private enum Field { case name, amount }
    @FocusState private var focusedField: Field?

    @State private var medicationName = ""
    @State private var amount = ""
    @State private var timeTaken = Date.now
    @State private var painScore = 0
    @State private var isShowingDiscardConfirmation = false
    @State private var isShowingSaveError = false

    private var trimmedName: String {
        medicationName.trimmingCharacters(in: .whitespaces)
    }

    private var trimmedAmount: String {
        amount.trimmingCharacters(in: .whitespaces)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty && !trimmedAmount.isEmpty
    }

    /// Whether the person has entered anything worth not losing silently.
    private var hasUnsavedInput: Bool {
        !trimmedName.isEmpty || !trimmedAmount.isEmpty || painScore != 0
    }

    /// Plan medication names that fit what's been typed, minus an exact match.
    private var nameSuggestions: [String] {
        suggestions(from: plans.map(\.medicationName), matching: trimmedName)
    }

    /// Plan amounts that fit what's been typed. With no name yet, every plan
    /// amount is offered; once there's a name, only that plan medication's
    /// amount is, and nothing for a medication that isn't in the plan, so one
    /// drug's dose is never suggested for another.
    private var amountSuggestions: [String] {
        let source = trimmedName.isEmpty
            ? plans
            : plans.filter {
                $0.medicationName.caseInsensitiveCompare(trimmedName) == .orderedSame
            }
        return suggestions(from: source.map(\.amountPerDose), matching: trimmedAmount)
    }

    private func suggestions(from values: [String], matching typed: String) -> [String] {
        var seen = Set<String>()
        return values.filter { value in
            guard seen.insert(value.lowercased()).inserted else { return false }
            guard value.caseInsensitiveCompare(typed) != .orderedSame else { return false }
            return typed.isEmpty || value.localizedCaseInsensitiveContains(typed)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    // Autocorrect must stay off: it silently rewrites drug names.
                    TextField("Name", text: $medicationName)
                        .focused($focusedField, equals: .name)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                    if focusedField == .name {
                        ForEach(nameSuggestions, id: \.self) { name in
                            SuggestionRow(text: name) {
                                medicationName = name
                                focusedField = .amount
                            }
                        }
                    }
                    TextField("Amount", text: $amount)
                        .focused($focusedField, equals: .amount)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if focusedField == .amount {
                        ForEach(amountSuggestions, id: \.self) { value in
                            SuggestionRow(text: value) {
                                amount = value
                                focusedField = nil
                            }
                        }
                    }
                }
                Section("Time") {
                    // Time only: the date stays today, so a logged dose always
                    // lands in the Today list instead of silently going elsewhere.
                    DatePicker(
                        "Time taken",
                        selection: $timeTaken,
                        in: ...Date.now,
                        displayedComponents: .hourAndMinute
                    )
                }
                Section("Pain level") {
                    Stepper("Pain: \(painScore) / 10", value: $painScore, in: 0...10)
                }
            }
            .animation(.default, value: focusedField)
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
        .alert("Couldn't save this dose", isPresented: $isShowingSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again.")
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
            medicationName: trimmedName,
            amount: trimmedAmount,
            timeTaken: timeTaken,
            painScore: painScore
        )
        modelContext.insert(dose)
        // SwiftData autosaves on a delay; save now so a dose isn't lost if the
        // app is killed right after logging.
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.delete(dose)
            isShowingSaveError = true
        }
    }
}

/// One tappable suggestion taken from the person's plan.
private struct SuggestionRow: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "list.clipboard")
                    .foregroundStyle(.secondary)
                Text(text)
                Spacer()
                Text("From My Plan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("With a plan") {
    LogDoseSheet()
        .modelContainer(previewContainer(withPlan: true))
}

#Preview("No plan") {
    LogDoseSheet()
        .modelContainer(previewContainer(withPlan: false))
}

@MainActor
private func previewContainer(withPlan: Bool) -> ModelContainer {
    let container = try! ModelContainer(
        for: Dose.self, Plan.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    if withPlan {
        container.mainContext.insert(
            Plan(medicationName: "Ibuprofen", amountPerDose: "400mg", dosesPerDay: 2)
        )
    }
    return container
}
