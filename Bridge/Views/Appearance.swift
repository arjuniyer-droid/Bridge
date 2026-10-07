//
//  Appearance.swift
//  Bridge
//

import SwiftUI
import UIKit

// What the person has chosen in Settings: language, light or dark, the accent
// colour and the text size. Each is saved on the device and applied once, at the root of
// the app, so every screen follows without knowing about it.

/// The accent colour. All of them are muted, and each one is checked to read at
/// 5:1 or better as text on a white card and 7.5:1 on a dark one, and to carry
/// a white label on its button fill at 4.7:1 or better.
enum AccentChoice: String, CaseIterable, Identifiable {
    case teal, blue, sage, plum, graphite

    var id: String { rawValue }

    var name: LocalizedStringKey {
        switch self {
        case .teal: "Teal"
        case .blue: "Blue"
        case .sage: "Sage"
        case .plum: "Plum"
        case .graphite: "Graphite"
        }
    }

    /// Light mode, dark mode, and the deeper fill used behind white labels in
    /// dark mode, where the accent itself is pale enough to glare as a block.
    private var hex: (light: UInt32, dark: UInt32, darkFill: UInt32) {
        switch self {
        case .teal: (0x2B7075, 0x7FBFC4, 0x327D83)
        case .blue: (0x436CA3, 0x90B0DA, 0x4774AE)
        case .sage: (0x44795D, 0x78BA97, 0x467C5F)
        case .plum: (0x8C5A8C, 0xCAA0CA, 0x955F95)
        case .graphite: (0x696F77, 0xAAAFB6, 0x6E747C)
        }
    }

    /// Text, icons and the main data series.
    var accent: Color {
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? hex.dark : hex.light)
        })
    }

    /// A faint wash behind secondary buttons and icons.
    var wash: Color {
        Color(uiColor: UIColor { traits in
            let dark = traits.userInterfaceStyle == .dark
            return UIColor(hex: dark ? hex.dark : hex.light).withAlphaComponent(dark ? 0.18 : 0.12)
        })
    }

    /// The fill of a filled button.
    var fill: Color {
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? hex.darkFill : hex.light)
        })
    }
}

/// The app's language. The names are always written in their own language, so
/// someone who can't read the current one can still find theirs.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, english, spanish, chinese

    var id: String { rawValue }

    var name: LocalizedStringKey {
        switch self {
        case .system: "Match my iPhone"
        case .english: "English"
        case .spanish: "Español"
        case .chinese: "中文（简体）"
        }
    }

    /// nil on "system", which leaves the iPhone's own language and region alone.
    var locale: Locale? {
        switch self {
        case .system: nil
        case .english: Locale(identifier: "en")
        case .spanish: Locale(identifier: "es")
        case .chinese: Locale(identifier: "zh-Hans")
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var name: LocalizedStringKey {
        switch self {
        case .system: "Match my iPhone"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// nil lets the iPhone decide.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum TextSizeChoice: String, CaseIterable, Identifiable {
    case system, small, standard, large, larger, largest

    var id: String { rawValue }

    var name: LocalizedStringKey {
        switch self {
        case .system: "Match my iPhone"
        case .small: "Small"
        case .standard: "Standard"
        case .large: "Large"
        case .larger: "Larger"
        case .largest: "Largest"
        }
    }

    /// nil follows the iPhone's own text size setting.
    var size: DynamicTypeSize? {
        switch self {
        case .system: nil
        case .small: .small
        case .standard: .large
        case .large: .xxLarge
        case .larger: .accessibility1
        case .largest: .accessibility3
        }
    }
}

// MARK: - Applying it

extension EnvironmentValues {
    /// The fill behind white labels on filled buttons, set from the chosen accent.
    @Entry var accentFill: Color = AccentChoice.teal.fill
    /// A faint wash of the chosen accent.
    @Entry var accentWash: Color = AccentChoice.teal.wash
}

private struct AppearanceModifier: ViewModifier {
    @AppStorage("accentChoice") private var accent = AccentChoice.teal
    @AppStorage("appearanceMode") private var mode = AppearanceMode.system
    @AppStorage("textSizeChoice") private var textSize = TextSizeChoice.system
    @AppStorage("languageChoice") private var language = AppLanguage.system

    func body(content: Content) -> some View {
        content
            .tint(accent.accent)
            .environment(\.accentFill, accent.fill)
            .environment(\.accentWash, accent.wash)
            .preferredColorScheme(mode.colorScheme)
            .transformEnvironment(\.locale) { current in
                if let locale = language.locale { current = locale }
            }
            .transformEnvironment(\.dynamicTypeSize) { current in
                if let size = textSize.size { current = size }
            }
    }
}

extension View {
    /// Applies the person's chosen appearance to everything inside. Used once,
    /// at the root of the app.
    func chosenAppearance() -> some View {
        modifier(AppearanceModifier())
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
