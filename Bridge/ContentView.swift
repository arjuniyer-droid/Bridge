//
//  ContentView.swift
//  Bridge
//
//  Created by Arjun Iyer on 9/19/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "sun.max") {
                TodayView()
            }
            Tab("My Plan", systemImage: "checklist") {
                MyPlanView()
            }
            Tab("Patterns", systemImage: "chart.line.uptrend.xyaxis") {
                PatternsView()
            }
            Tab("Support", systemImage: "heart.circle") {
                SupportView()
            }
        }
    }
}

#Preview {
    ContentView()
}
