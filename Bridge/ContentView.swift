//
//  ContentView.swift
//  Bridge
//
//  Created by Arjun Iyer on 9/19/26.
//

import SwiftUI

struct ContentView: View {
    private enum AppTab: Hashable {
        case myPlan, history, today, patterns, support
    }

    // The app opens on Today even though it isn't the first tab.
    @State private var selectedTab = AppTab.today

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("My Plan", systemImage: "checklist", value: AppTab.myPlan) {
                MyPlanView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryView()
            }
            Tab("Today", systemImage: "sun.max", value: AppTab.today) {
                TodayView()
            }
            Tab("Patterns", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.patterns) {
                PatternsView()
            }
            Tab("Support", systemImage: "heart.circle", value: AppTab.support) {
                SupportView()
            }
        }
    }
}

#Preview {
    ContentView()
}
