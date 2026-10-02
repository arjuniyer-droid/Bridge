//
//  MyPlanView.swift
//  Bridge
//

import SwiftUI
import SwiftData

struct MyPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plan.medicationName) private var plans: [Plan]
    @State private var formTarget: FormTarget?
    @State private var pendingDeletion: PendingDeletion?
    @State private var isShowingDeleteError = false

    /// What the form sheet is showing. `plan` is nil when adding. The id is
    /// generated up front so the sheet never reads a plan that was deleted.
    private struct FormTarget: Identifiable {
        let plan: Plan?
        let id = UUID()
    }

    /// A plan awaiting confirmation. The name is copied so the confirmation
    /// text never reads a plan that has already been deleted.
    private struct PendingDeletion {
        let plan: Plan
        let name: String
    }

    private var isShowingDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if plans.isEmpty {
                    ContentUnavailableView {
                        Label("No plan yet", systemImage: "list.clipboard")
                    } description: {
                        Text("Add each medication your prescriber gave you.")
                    } actions: {
                        Button("Add Plan") { formTarget = FormTarget(plan: nil) }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section("Prescribed by your provider") {
                            ForEach(plans) { plan in
                                PlanRow(plan: plan) {
                                    formTarget = FormTarget(plan: plan)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        pendingDeletion = PendingDeletion(
                                            plan: plan,
                                            name: plan.medicationName
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Plan")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Plan", systemImage: "plus") {
                        formTarget = FormTarget(plan: nil)
                    }
                }
            }
            .sheet(item: $formTarget) { target in
                PlanFormSheet(plan: target.plan)
            }
            .confirmationDialog(
                "Delete this plan?",
                isPresented: isShowingDeleteConfirmation,
                titleVisibility: .visible,
                presenting: pendingDeletion
            ) { pending in
                Button("Delete", role: .destructive) { delete(pending.plan) }
                Button("Cancel", role: .cancel) {}
            } message: { pending in
                Text("This will remove \(pending.name) from your plan. This can't be undone.")
            }
            .alert("Couldn't delete this plan", isPresented: $isShowingDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again.")
            }
        }
    }

    private func delete(_ plan: Plan) {
        modelContext.delete(plan)
        // Save now rather than waiting for SwiftData's delayed autosave.
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            isShowingDeleteError = true
        }
    }
}

private struct PlanRow: View {
    let plan: Plan
    let onEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.medicationName)
                    .font(.headline)
                Text("\(plan.amountPerDose) · \(plan.dosesPerDay) per day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Edit", action: onEdit)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MyPlanView()
        .modelContainer(for: Plan.self, inMemory: true)
}
