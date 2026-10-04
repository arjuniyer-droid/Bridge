//
//  Theme.swift
//  Bridge
//

import SwiftUI
import UIKit

/// The app uses one accent colour, the AccentColor asset (a deep teal in light
/// mode, a lighter teal in dark mode). It marks things you can tap and the
/// main data series. Everything else is neutral: primary and secondary text
/// and grey fills. Don't add a second colour; use a neutral instead.
extension Color {
    /// Text and icons on top of a filled accent button. White on the deep
    /// light-mode teal, black on the lighter dark-mode teal, because white
    /// would be too faint on the lighter one.
    static let onAccent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .black : .white
    })
}

/// The smallest tappable size Apple recommends, in points.
let minimumTapSize: CGFloat = 44

/// A stepper with large minus and plus buttons, in place of SwiftUI's Stepper,
/// whose buttons are only about 32 points tall. The pain score is the most
/// repeated input in the app, so it has to be easy to hit.
struct ThumbStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
            stepButton("minus", change: -1, label: "Decrease")
            stepButton("plus", change: 1, label: "Increase")
        }
        // VoiceOver users swipe up or down to change the value, as with Stepper.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + 1, range.upperBound)
            case .decrement: value = max(value - 1, range.lowerBound)
            @unknown default: break
            }
        }
    }

    private func stepButton(_ symbol: String, change: Int, label: String) -> some View {
        let target = value + change
        return Button {
            value = min(max(target, range.lowerBound), range.upperBound)
        } label: {
            Image(systemName: symbol)
                .font(.headline)
                .frame(width: minimumTapSize - 12, height: minimumTapSize - 12)
        }
        // Borderless, so each button is tapped on its own instead of the whole
        // form row acting as one button.
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .disabled(!range.contains(target))
        .accessibilityLabel(label)
    }
}
