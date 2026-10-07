//
//  DisclaimerFooter.swift
//  Bridge
//

import SwiftUI

/// The reminder shown at the bottom of every screen.
struct DisclaimerFooter: View {
    var body: some View {
        Text("Bridge does not give medical advice. Your prescriber is the only authority.")
            .font(.bridge(.caption))
            .foregroundStyle(Color.textSecondary)
            .multilineTextAlignment(.center)
            // This bar is pinned to every screen. At the largest accessibility
            // text sizes it would otherwise fill about 40% of the screen and
            // squeeze the content, so its own text stops growing at this size.
            // Everything else on screen still scales.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Space.unit)
            .padding(.vertical, Space.half)
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
