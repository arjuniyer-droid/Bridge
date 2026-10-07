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
                    Screen(footer: true) {
                        EmptyStateCard(
                            systemImage: "list.clipboard",
                            title: "No plan yet",
                            message: "Add each medication your prescriber gave you."
                        )
                        Button("Add Plan") { formTarget = FormTarget(plan: nil) }
                            .buttonStyle(.bridgePrimary)
                    }
                } else {
                    // A List, so each plan can still be swiped to delete. The
                    // rows are drawn as cards.
                    List {
                        Section {
                            ForEach(plans) { plan in
                                PlanCard(plan: plan) {
                                    formTarget = FormTarget(plan: plan)
                                }
                                .listRowInsets(EdgeInsets(
                                    top: Space.half, leading: Space.unit,
                                    bottom: Space.half, trailing: Space.unit
                                ))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        pendingDeletion = PendingDeletion(
                                            plan: plan,
                                            name: plan.medicationName
                                        )
                                    }
                                }
                            }
                        } header: {
                            // The list already insets its headers by one grid unit,
                            // which lines this up with the cards' left edge.
                            SectionTitle("Prescribed by your provider")
                                .textCase(nil)
                        }
                        .listSectionSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.screenBackground.ignoresSafeArea())
                    .disclaimerFooter()
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

/// One medication in the plan.
private struct PlanCard: View {
    let plan: Plan
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: Space.unit) {
            VStack(alignment: .leading, spacing: Space.tight) {
                Text(plan.medicationName)
                    .font(.bridge(.headline))
                    .foregroundStyle(Color.textPrimary)
                Text("\(plan.amountPerDose) · \(plan.dosesPerDay) per day")
                    .font(.bridge(.secondary))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: Space.half)
            Button("Edit", action: onEdit)
                .buttonStyle(.bridgeSecondaryCompact)
        }
        .card()
    }
}

#Preview {
    MyPlanView()
        .modelContainer(for: Plan.self, inMemory: true)
}
