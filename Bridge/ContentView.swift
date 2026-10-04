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
                TodayView().disclaimerFooter()
            }
            Tab("My Plan", systemImage: "checklist") {
                MyPlanView().disclaimerFooter()
            }
            Tab("Patterns", systemImage: "chart.line.uptrend.xyaxis") {
                PatternsView().disclaimerFooter()
            }
            Tab("Support", systemImage: "heart.circle") {
                SupportView().disclaimerFooter()
            }
        }
    }
}

#Preview {
    ContentView()
}
