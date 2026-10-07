//
//  SettingsView.swift
//  Bridge
//

import SwiftUI

/// Appearance settings. Every change applies to the whole app straight away and
/// is remembered; none of it touches the person's doses or plan.
struct SettingsView: View {
    @AppStorage("accentChoice") private var accent = AccentChoice.teal
    @AppStorage("appearanceMode") private var mode = AppearanceMode.system
    @AppStorage("textSizeChoice") private var textSize = TextSizeChoice.system
    @AppStorage("languageChoice") private var language = AppLanguage.system

    private var isDefault: Bool {
        accent == .teal && mode == .system && textSize == .system && language == .system
    }

    var body: some View {
        NavigationStack {
            Screen(footer: true) {
                VStack(alignment: .leading, spacing: Space.half) {
                    SectionTitle("Language")
                    DividedStack {
                        ForEach(AppLanguage.allCases) { option in
                            OptionRow(title: option.name, isSelected: language == option) {
                                language = option
                            }
                        }
                    }
                    .card(padded: false)
                }

                VStack(alignment: .leading, spacing: Space.half) {
                    SectionTitle("Appearance")
                    DividedStack {
                        ForEach(AppearanceMode.allCases) { option in
                            OptionRow(title: option.name, isSelected: mode == option) {
                                mode = option
                            }
                        }
                    }
                    .card(padded: false)
                }

                VStack(alignment: .leading, spacing: Space.half) {
                    SectionTitle("Color")
                    DividedStack {
                        ForEach(AccentChoice.allCases) { option in
                            OptionRow(title: option.name, isSelected: accent == option) {
                                accent = option
                            } leading: {
                                Circle()
                                    .fill(option.accent)
                                    .frame(width: Space.unit + Space.half, height: Space.unit + Space.half)
                            }
                        }
                    }
                    .card(padded: false)
                    CardNote("All of these are muted on purpose, and each stays easy to read in light and dark mode.")
                }

                VStack(alignment: .leading, spacing: Space.half) {
                    SectionTitle("Text size")
                    DividedStack {
                        ForEach(TextSizeChoice.allCases) { option in
                            OptionRow(title: option.name, isSelected: textSize == option) {
                                textSize = option
                            }
                        }
                    }
                    .card(padded: false)
                    sample
                    CardNote("\"Match my iPhone\" follows Settings > Accessibility > Display & Text Size on your phone.")
                }

                Button("Reset to defaults") {
                    accent = .teal
                    mode = .system
                    textSize = .system
                    language = .system
                }
                .buttonStyle(.bridgeSecondary)
                .disabled(isDefault)
            }
            .navigationTitle("Settings")
        }
    }

    /// A line of text at the chosen size, so the effect can be seen here.
    private var sample: some View {
        VStack(alignment: .leading, spacing: Space.tight) {
            Text("Ibuprofen")
                .font(.bridge(.headline))
                .foregroundStyle(Color.textPrimary)
            Text("400mg · 8:00 AM")
                .font(.bridge(.secondary))
                .foregroundStyle(Color.textSecondary)
        }
        .cardRow()
        .card(padded: false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sample text at this size")
    }
}

/// A row in a list of choices: a name and a check mark on the selected one.
private struct OptionRow<Leading: View>: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let leading: Leading

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.unit) {
                leading
                Text(title)
                    .font(.bridge(.body))
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.bridge(.headline))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .cardRow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension OptionRow where Leading == EmptyView {
    init(title: LocalizedStringKey, isSelected: Bool, action: @escaping () -> Void) {
        self.init(title: title, isSelected: isSelected, action: action) { EmptyView() }
    }
}

#Preview {
    SettingsView()
}
