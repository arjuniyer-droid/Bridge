//
//  Localization.swift
//  Bridge
//

import Foundation

/// Looks up text in the language the app is showing, for the strings that are
/// built in code rather than written straight into a `Text`. SwiftUI picks the
/// language for `Text` from the environment's locale; this does the same for
/// everything else, so the two always agree.
struct Lang {
    let locale: Locale
    private let bundle: Bundle

    /// The language for a locale taken from the SwiftUI environment.
    init(_ locale: Locale) {
        self.locale = locale
        let code = Bundle.preferredLocalizations(
            from: Bundle.main.localizations,
            forPreferences: [locale.identifier]
        ).first
        if let code,
           let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = .main
        }
    }

    func callAsFunction(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: bundle, locale: locale)
    }
}
