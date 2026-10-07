//
//  ContentView.swift
//  Bridge
//
//  Created by Arjun Iyer on 9/19/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.locale) private var locale

    var body: some View {
        // The screens that aren't showing when the language changes are rebuilt,
        // because a navigation bar's title doesn't pick up the new language on
        // its own. The tab selection is kept, and so is Settings, which is the
        // screen the change is made on.
        TabView {
            Tab("Today", systemImage: "sun.max") {
                TodayView().id(locale.identifier)
            }
            Tab("My Plan", systemImage: "checklist") {
                MyPlanView().id(locale.identifier)
            }
            Tab("Patterns", systemImage: "chart.line.uptrend.xyaxis") {
                PatternsView().id(locale.identifier)
            }
            Tab("Support", systemImage: "heart.circle") {
                SupportView().id(locale.identifier)
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
