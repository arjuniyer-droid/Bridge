//
//  DoseFormSheet.swift
//  Bridge
//

import SwiftUI
import SwiftData

/// What the dose form is showing: a new dose when `dose` is nil, otherwise a
/// logged dose being corrected. The id is generated up front so the sheet
/// never reads a dose that was deleted.
struct DoseFormTarget: Identifiable {
    let dose: Dose?
    let id = UUID()
}

/// A form, presented as a sheet, for logging a dose or correcting one that was
/// already logged. Tapping the name or amount field offers what's in the
/// person's plan; typing a different value still works.
struct DoseFormSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Plan.medicationName) private var plans: [Plan]

    private enum Field { case name, amount }
    @FocusState private var focusedField: Field?

    /// The dose being corrected, or nil when logging a new one.
    let dose: Dose?

    // The values the form started with. Copied up front so the view never
    // reads `dose` after it has been deleted.
    private let originalName: String
    private let originalAmount: String
    private let originalTime: Date
    private let originalPain: Int

    @State private var medicationName: String
    @State private var amount: String
    @State private var timeTaken: Date
    @State private var painScore: Int
    @State private var isShowingDiscardConfirmation = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingError = false
    @State private var errorTitle = ""

    init(dose: Dose? = nil) {
        self.dose = dose
        originalName = dose?.medicationName ?? ""
        originalAmount = dose?.amount ?? ""
        originalTime = dose?.timeTaken ?? .now
        originalPain = dose?.painScore ?? 0
        _medicationName = State(initialValue: dose?.medicationName ?? "")
        _amount = State(initialValue: dose?.amount ?? "")
        _timeTaken = State(initialValue: dose?.timeTaken ?? .now)
        _painScore = State(initialValue: dose?.painScore ?? 0)
    }

    private var isEditing: Bool { dose != nil }

    private var trimmedName: String {
        medicationName.trimmingCharacters(in: .whitespaces)
    }

    private var trimmedAmount: String {
        amount.trimmingCharacters(in: .whitespaces)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty && !trimmedAmount.isEmpty
    }

    /// Whether anything differs from what the form started with. For a new
    /// dose that is anything entered, which is worth not losing silently.
    private var hasChanges: Bool {
        trimmedName != originalName
            || trimmedAmount != originalAmount
            || painScore != originalPain
            || (isEditing && timeTaken != originalTime)
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
                    if isEditing {
                        // A correction can fix the day as well as the time. The
                        // History tab shows every day, so the dose won't vanish.
                        DatePicker(
                            "Taken",
                            selection: $timeTaken,
                            in: ...Date.now,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    } else {
                        // Time only: a new dose is for today, so it always
                        // lands in the Today list.
                        DatePicker(
                            "Time taken",
                            selection: $timeTaken,
                            in: ...Date.now,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                Section("Pain level") {
                    ThumbStepper(title: "Pain: \(painScore) / 10", value: $painScore, range: 0...10)
                }
                if isEditing {
                    Section {
                        Button("Delete Dose", role: .destructive) {
                            isShowingDeleteConfirmation = true
                        }
                    }
                }
            }
            .animation(.default, value: focusedField)
            .confirmationDialog(
                "Delete this dose?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteDose() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove \(originalName) (\(originalAmount)) logged \(originalTime.formatted(date: .abbreviated, time: .shortened)). This can't be undone.")
            }
            .navigationTitle(isEditing ? "Edit Dose" : "Log a Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { requestDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid || (isEditing && !hasChanges))
                }
            }
            // Prevent a stray swipe from closing the sheet and silently
            // discarding whatever the person has already typed.
            .interactiveDismissDisabled(hasChanges)
        }
        .disclaimerFooter()
        .confirmationDialog(
            isEditing ? "Discard your changes?" : "Discard this dose?",
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
        if hasChanges {
            isShowingDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func save() {
        if let dose {
            dose.medicationName = trimmedName
            dose.amount = trimmedAmount
            dose.timeTaken = timeTaken
            dose.painScore = painScore
        } else {
            modelContext.insert(
                Dose(
                    medicationName: trimmedName,
                    amount: trimmedAmount,
                    timeTaken: timeTaken,
                    painScore: painScore
                )
            )
        }
        // SwiftData autosaves on a delay; save now so a dose isn't lost if the
        // app is killed right after logging or correcting it.
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorTitle = isEditing ? "Couldn't save your changes" : "Couldn't save this dose"
            isShowingError = true
        }
    }

    private func deleteDose() {
        guard let dose else { return }
        modelContext.delete(dose)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorTitle = "Couldn't delete this dose"
            isShowingError = true
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

#Preview("Log") {
    DoseFormSheet()
        .modelContainer(for: [Dose.self, Plan.self], inMemory: true)
}
