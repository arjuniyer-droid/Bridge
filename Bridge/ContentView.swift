//
//  ContentView.swift
//  Bridge
//
//  Created by Arjun Iyer on 9/19/26.
//

import SwiftUI

enum AppTab: Hashable {
    case today, plan, patterns, support, settings
}

extension EnvironmentValues {
    /// Switches to another tab, for an empty state whose next step is elsewhere.
    @Entry var selectTab: (AppTab) -> Void = { _ in }
}

struct ContentView: View {
    @Environment(\.locale) private var locale
    @State private var selection = AppTab.today
    /// Whether the welcome screens have been seen. They show once, on first launch.
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        // The screens that aren't showing when the language changes are rebuilt,
        // because a navigation bar's title doesn't pick up the new language on
        // its own. The tab selection is kept, and so is Settings, which is the
        // screen the change is made on.
        TabView(selection: $selection) {
            Tab("Today", systemImage: "sun.max", value: AppTab.today) {
                TodayView().id(locale.identifier).fadeInOnAppear()
            }
            Tab("My Plan", systemImage: "checklist", value: AppTab.plan) {
                MyPlanView().id(locale.identifier).fadeInOnAppear()
            }
            Tab("Patterns", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.patterns) {
                PatternsView().id(locale.identifier).fadeInOnAppear()
            }
            Tab("Support", systemImage: "heart.circle", value: AppTab.support) {
                SupportView().id(locale.identifier).fadeInOnAppear()
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                SettingsView().fadeInOnAppear()
            }
        }
        .environment(\.selectTab) { selection = $0 }
        .fullScreenCover(isPresented: Binding(
            get: { !hasSeenOnboarding },
            set: { if !$0 { hasSeenOnboarding = true } }
        )) {
            OnboardingView { hasSeenOnboarding = true }
        }
    }
}

#Preview {
    ContentView()
}
