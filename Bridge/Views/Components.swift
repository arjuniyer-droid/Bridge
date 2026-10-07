//
//  Components.swift
//  Bridge
//

import SwiftUI

/// The standard screen: scrolling content on the grouped background, 16 pt
/// margins and 16 pt between cards.
struct Screen<Content: View>: View {
    private let showsFooter: Bool
    private let content: Content

    /// `footer` pins the medical disclaimer under the content. It is applied to
    /// the scroll view itself, because a footer added outside the navigation
    /// stack does not make the scroll view stop above it, which leaves the last
    /// card unreachable underneath.
    init(footer: Bool = false, @ViewBuilder content: () -> Content) {
        self.showsFooter = footer
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.unit) {
                content
            }
            .padding(Space.unit)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.screenBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsFooter { DisclaimerFooter() }
        }
    }
}

/// A heading above a card.
struct SectionTitle: View {
    private let text: Text

    init(_ key: LocalizedStringKey) {
        text = Text(key)
    }

    /// For text that is already final, such as a date.
    init(verbatim text: String) {
        self.text = Text(verbatim: text)
    }

    var body: some View {
        text
            .font(.bridge(.headline))
            .foregroundStyle(Color.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// A short note under a card.
struct CardNote: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.bridge(.caption))
            .foregroundStyle(Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A card that says there is nothing here yet.
struct EmptyStateCard: View {
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: Space.half) {
            Image(systemName: systemImage)
                .font(.bridge(.title))
                .imageScale(.large)
                .foregroundStyle(.tint)
                .padding(.bottom, Space.half)
                .accessibilityHidden(true)
            Text(title)
                .font(.bridge(.headline))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.bridge(.secondary))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Space.double)
        .card()
        .accessibilityElement(children: .combine)
    }
}

/// Rows stacked in a card with a hairline between each. The rows pad
/// themselves, so use it with `card(padded: false)`.
struct DividedStack<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group(subviews: content) { subviews in
            VStack(spacing: 0) {
                // Keyed by each row's own identity, not its position, so a row
                // keeps its identity and keyboard focus when rows above it
                // come and go (the plan suggestions under a text field).
                ForEach(subviews) { subview in
                    subview
                    if subview.id != subviews.last?.id {
                        Divider().padding(.leading, Space.unit)
                    }
                }
            }
        }
    }
}

/// A stepper with large minus and plus buttons, in place of SwiftUI's Stepper,
/// whose buttons are only about 32 points tall. The pain score is the most
/// repeated input in the app, so it has to be easy to hit.
struct ThumbStepper: View {
    let title: LocalizedStringKey
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: Space.half) {
            Text(title)
                .font(.bridge(.body))
                .foregroundStyle(Color.textPrimary)
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

    private func stepButton(_ symbol: String, change: Int, label: LocalizedStringKey) -> some View {
        let target = value + change
        return Button {
            value = min(max(target, range.lowerBound), range.upperBound)
        } label: {
            Image(systemName: symbol)
        }
        .buttonStyle(.bridgeCircle)
        .disabled(!range.contains(target))
        .accessibilityLabel(label)
    }
}

/// The hint inside an empty text field. iOS's default hint colour is only about
/// 1.8:1 on white, and these hints are the fields' only visible labels.
func prompt(_ text: LocalizedStringKey) -> Text {
    Text(text).foregroundStyle(Color.textSecondary)
}
