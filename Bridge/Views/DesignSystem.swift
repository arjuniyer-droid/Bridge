//
//  DesignSystem.swift
//  Bridge
//

import SwiftUI
import UIKit

// Bridge's design system: calm, quiet, trustworthy.
//
// - One muted teal accent (the AccentColor asset). It marks what you can tap and
//   the main data series. Everything else is neutral.
// - The system font (SF Pro) at one set of sizes, `Font.bridge`, all of them
//   Dynamic Type styles so they follow the person's text size.
// - Content sits in cards: 16 pt rounded corners, a soft shadow, on the grouped
//   background. Spacing follows a 16 pt grid.
// - Every colour is a token below that follows light and dark mode itself.
//
// New screens use these tokens. Don't write a colour, font size or spacing
// number in a view; add or reuse a token here instead.

// MARK: - Spacing and shape

enum Space {
    /// The grid: screen margins, card padding and the gap between cards.
    static let unit: CGFloat = 16
    /// Half a unit: gaps within a card, such as between a title and its content.
    static let half: CGFloat = 8
    /// Two units: between larger groups.
    static let double: CGFloat = 32
    /// A quarter unit: only between lines of text that belong together.
    static let tight: CGFloat = 4
}

enum Radius {
    static let card: CGFloat = 16
    /// Smaller controls, such as secondary buttons.
    static let control: CGFloat = 12
    /// The ends of chart bars.
    static let bar: CGFloat = 4
}

/// The smallest tappable size Apple recommends, in points.
let minimumTapSize: CGFloat = 44

// MARK: - Colour

extension Color {
    // Surfaces
    static let screenBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let hairline = Color(uiColor: .separator)

    // Text
    static let textPrimary = Color(uiColor: .label)

    /// Secondary text. iOS's own secondary grey is only 3.4:1 on white, below
    /// the 4.5:1 small text needs, so light mode uses a darker grey (6.5:1).
    /// Dark mode keeps the system one, which already passes.
    static let textSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.secondaryLabel.resolvedColor(with: traits)
            : UIColor(red: 0.369, green: 0.369, blue: 0.388, alpha: 1)      // #5E5E63
    })

    /// Text and icons on top of a filled accent button.
    static let onAccent = Color.white

    /// Delete. iOS's red is 3.6:1 on white, so light mode uses a deeper one
    /// (6.6:1) and dark mode a softer one.
    static let destructive = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.000, green: 0.604, blue: 0.565, alpha: 1)      // #FF9A90
            : UIColor(red: 0.706, green: 0.137, blue: 0.094, alpha: 1)      // #B42318
    })
}

// MARK: - Type scale

/// The whole type scale. SF Pro, every size a Dynamic Type style.
enum TypeRole {
    /// A card's or sheet's title, and the large numbers.
    case title
    /// A row's name or a card's heading.
    case headline
    /// Reading text and form fields.
    case body
    /// Descriptions under a name.
    case secondary
    /// Hints, footers and small notes.
    case caption
    case captionStrong
    /// The smallest text, for chart labels and tags.
    case fine
    case fineStrong
}

extension Font {
    static func bridge(_ role: TypeRole) -> Font {
        switch role {
        case .title: .title2.weight(.semibold)
        case .headline: .headline
        case .body: .body
        case .secondary: .subheadline
        case .caption: .footnote
        case .captionStrong: .footnote.weight(.semibold)
        case .fine: .caption
        case .fineStrong: .caption.weight(.semibold)
        }
    }
}

// MARK: - Cards

/// 16 pt rounded corners, a soft shadow in light mode, and a hairline edge in
/// dark mode, where a shadow can't be seen.
private struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    let padded: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
        content
            .padding(padded ? Space.unit : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground, in: shape)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.hairline.opacity(scheme == .dark ? 0.4 : 0), lineWidth: 0.5))
            .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    /// Puts the view in a card. Pass `padded: false` for a card of rows that
    /// pad themselves, so their dividers can run edge to edge.
    func card(padded: Bool = true) -> some View {
        modifier(CardStyle(padded: padded))
    }

    /// The padding of a row inside a card.
    func cardRow() -> some View {
        padding(Space.unit)
            .frame(maxWidth: .infinity, minHeight: minimumTapSize, alignment: .leading)
    }
}

// MARK: - Buttons

/// The main action on a screen: a full-width muted teal button.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accentFill) private var accentFill

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
        configuration.label
            .font(.bridge(.headline))
            .foregroundStyle(Color.onAccent)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, Space.unit)
            .background(accentFill, in: shape)
            .contentShape(shape)
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
    }
}

/// Everything else you can tap: accent text on a faint wash of the accent.
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accentWash) private var accentWash
    /// Full width, or only as wide as its label.
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
        configuration.label
            .font(.bridge(.headline))
            .foregroundStyle(.tint)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: minimumTapSize)
            .padding(.horizontal, Space.unit)
            .background(accentWash, in: shape)
            .contentShape(shape)
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
    }
}

/// A round icon button, such as the minus and plus on a stepper.
struct CircleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accentWash) private var accentWash

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bridge(.headline))
            .foregroundStyle(.tint)
            .frame(width: minimumTapSize, height: minimumTapSize)
            .background(accentWash, in: Circle())
            .contentShape(Circle())
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.35)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var bridgePrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var bridgeSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
    static var bridgeSecondaryCompact: SecondaryButtonStyle { SecondaryButtonStyle(fullWidth: false) }
}

extension ButtonStyle where Self == CircleButtonStyle {
    static var bridgeCircle: CircleButtonStyle { CircleButtonStyle() }
}
