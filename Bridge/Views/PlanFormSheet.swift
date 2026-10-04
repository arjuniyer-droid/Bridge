//
//  PlanFormSheet.swift
//  Bridge
//

import SwiftUI
import SwiftData

/// A form, presented as a sheet, for entering the prescriber's plan or editing
/// an existing one. Pass `nil` to add a plan.
struct PlanFormSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let plan: Plan?

    // The values the form started with. Copied up front so the view never
    // reads `plan` after it has been deleted.
    private let originalName: String
    private let originalAmount: String
    private let originalDosesPerDay: Int

    @State private var medicationName: String
    @State private var amountPerDose: String
    @State private var dosesPerDay: Int
    @State private var isShowingDiscardConfirmation = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingError = false
    @State private var errorTitle = ""

    init(plan: Plan?) {
        self.plan = plan
        originalName = plan?.medicationName ?? ""
        originalAmount = plan?.amountPerDose ?? ""
        originalDosesPerDay = plan?.dosesPerDay ?? 1
        _medicationName = State(initialValue: plan?.medicationName ?? "")
        _amountPerDose = State(initialValue: plan?.amountPerDose ?? "")
        _dosesPerDay = State(initialValue: plan?.dosesPerDay ?? 1)
    }

    private var trimmedName: String {
        medicationName.trimmingCharacters(in: .whitespaces)
    }

    private var trimmedAmount: String {
        amountPerDose.trimmingCharacters(in: .whitespaces)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty && !trimmedAmount.isEmpty
    }

    /// Whether anything differs from what the form started with.
    private var hasUnsavedChanges: Bool {
        trimmedName != originalName
            || trimmedAmount != originalAmount
            || dosesPerDay != originalDosesPerDay
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    // Autocorrect must stay off: it silently rewrites drug names.
                    TextField("Name", text: $medicationName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
                Section("Amount per dose") {
                    TextField("e.g. 400mg", text: $amountPerDose)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                Section("Doses per day") {
                    ThumbStepper(
                        title: "\(dosesPerDay) per day",
                        value: $dosesPerDay,
                        range: Plan.dosesPerDayRange
                    )
                }
                if plan != nil {
                    Section {
                        Button("Delete Plan", role: .destructive) {
                            isShowingDeleteConfirmation = true
                        }
                    }
                }
            }
            .confirmationDialog(
                "Delete this plan?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deletePlan() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove \(originalName) from your plan. This can't be undone.")
            }
            .navigationTitle(plan == nil ? "Add Plan" : "Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { requestDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid || !hasUnsavedChanges)
                }
            }
            // A stray swipe shouldn't silently discard what was typed.
            .interactiveDismissDisabled(hasUnsavedChanges)
        }
        .disclaimerFooter()
        .confirmationDialog(
            "Discard your changes?",
            isPresented: $isShowingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        }
        .alert(errorTitle, isPresented: $isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again.")
        }
    }

    private func requestDismiss() {
        if hasUnsavedChanges {
            isShowingDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func save() {
        if let plan {
            plan.medicationName = trimmedName
            plan.amountPerDose = trimmedAmount
            plan.dosesPerDay = dosesPerDay
        } else {
            modelContext.insert(
                Plan(
                    medicationName: trimmedName,
                    amountPerDose: trimmedAmount,
                    dosesPerDay: dosesPerDay
                )
            )
        }
        // Save now rather than waiting for SwiftData's delayed autosave.
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorTitle = "Couldn't save your plan"
            isShowingError = true
        }
    }

    private func deletePlan() {
        guard let plan else { return }
        modelContext.delete(plan)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorTitle = "Couldn't delete this plan"
            isShowingError = true
        }
    }
}

#Preview("New") {
    PlanFormSheet(plan: nil)
        .modelContainer(for: Plan.self, inMemory: true)
}

#Preview("Edit") {
    PlanFormSheet(plan: Plan(medicationName: "Ibuprofen", amountPerDose: "400mg", dosesPerDay: 3))
        .modelContainer(for: Plan.self, inMemory: true)
}
