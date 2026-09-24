//
//  TodayView.swift
//  Bridge
//

import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            Text("Today")
                .font(.largeTitle)
                .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
}
