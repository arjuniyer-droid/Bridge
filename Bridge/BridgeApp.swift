//
//  BridgeApp.swift
//  Bridge
//
//  Created by Arjun Iyer on 9/19/26.
//

import SwiftUI
import SwiftData

@main
struct BridgeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .chosenAppearance()
        }
        .modelContainer(for: [Dose.self, Plan.self])
    }
}
