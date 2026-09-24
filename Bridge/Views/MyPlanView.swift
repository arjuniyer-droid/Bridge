//
//  MyPlanView.swift
//  Bridge
//

import SwiftUI

struct MyPlanView: View {
    var body: some View {
        NavigationStack {
            Text("My Plan")
                .font(.largeTitle)
                .navigationTitle("My Plan")
        }
    }
}

#Preview {
    MyPlanView()
}
