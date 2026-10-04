//
//  DisclaimerFooter.swift
//  Bridge
//

import SwiftUI

/// The reminder shown at the bottom of every screen.
struct DisclaimerFooter: View {
    static let text = "Bridge does not give medical advice. Your prescriber is the only authority."

    var body: some View {
        Text(Self.text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
    }
}

extension View {
    /// Pins the disclaimer to the bottom edge, above the tab bar, with the
    /// screen's own content inset so nothing scrolls underneath it.
    func disclaimerFooter() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            DisclaimerFooter()
        }
    }
}
