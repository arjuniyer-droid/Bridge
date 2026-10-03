//
//  TodayView.swift
//  Bridge
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var todaysDoses: [Dose]
    @State private var isShowingLogDose = false

    init() {
        let startOfToday = Calendar.current.startOfDay(for: .now)
        let startOfTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
        let predicate = #Predicate<Dose> { dose in
            dose.timeTaken >= startOfToday && dose.timeTaken < startOfTomorrow
        }
        _todaysDoses = Query(filter: predicate, sort: \Dose.timeTaken, order: .reverse)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Button {
                    isShowingLogDose = true
                } label: {
                    Label("Log a Dose", systemImage: "plus.circle.fill")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.top, 8)

                if todaysDoses.isEmpty {
                    ContentUnavailableView(
                        "No doses logged today",
                        systemImage: "pills",
                        description: Text("Doses you log today will show up here.")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List(todaysDoses) { dose in
                        DoseRow(dose: dose)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Today")
            .sheet(isPresented: $isShowingLogDose) {
                LogDoseSheet()
            }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Dose.self, Plan.self], inMemory: true)
}
