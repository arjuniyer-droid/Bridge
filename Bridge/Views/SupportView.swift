//
//  SupportView.swift
//  Bridge
//

import SwiftUI

/// Phone numbers and short descriptions were checked against samhsa.gov,
/// veteranscrisisline.net and the VA Palo Alto contact page (va.gov) in
/// October 2026. Phone numbers change, so recheck them before each release.
struct SupportView: View {
    /// Remembered between launches, so a veteran only has to switch it on once.
    @AppStorage("showsVeteranResources") private var showsVeteranResources = false

    var body: some View {
        NavigationStack {
            Screen(footer: true) {
                VStack(alignment: .leading, spacing: Space.half) {
                    SectionTitle("Talk to someone")
                    DividedStack {
                        PhoneRow(
                            name: "SAMHSA National Helpline",
                            number: "1-800-662-4357",
                            dialing: "tel:18006624357",
                            detail: "Free, confidential, 24 hours a day, every day, in English and Spanish. Treatment referral and information for mental health and substance use."
                        )
                        PhoneRow(
                            name: "Veterans Crisis Line",
                            number: "Dial 988, then press 1",
                            dialing: "tel:988",
                            detail: "Free, confidential, 24 hours a day, every day. For veterans, service members, National Guard and Reserve members, and those who support them. You don't need to be enrolled in VA benefits or health care."
                        )
                    }
                    .card(padded: false)
                    CardNote("Tapping a number starts a call. For the Veterans Crisis Line, the call goes to 988 and you press 1 yourself when it connects.")
                }

                VStack(alignment: .leading, spacing: Space.half) {
                    Toggle(isOn: $showsVeteranResources) {
                        Text("I'm a veteran")
                            .font(.bridge(.body))
                            .foregroundStyle(Color.textPrimary)
                    }
                    .cardRow()
                    .card(padded: false)
                    CardNote("Adds VA Palo Alto Health Care System resources below.")
                }

                if showsVeteranResources {
                    VStack(alignment: .leading, spacing: Space.half) {
                        SectionTitle("VA Palo Alto Health Care System")
                        DividedStack {
                            PhoneRow(
                                name: "Mental health care appointments",
                                number: "855-632-8262",
                                dialing: "tel:8556328262",
                                detail: "Scheduling line for all VA Palo Alto sites."
                            )
                            PhoneRow(
                                name: "Addiction and substance abuse care",
                                number: "650-493-5000, ext. 60050",
                                dialing: "tel:6504935000,60050",
                                detail: "Calls the main number, then pauses and dials the extension."
                            )
                            PhoneRow(
                                name: "Main number, toll-free",
                                number: "833-983-0487",
                                dialing: "tel:8339830487",
                                detail: "Local: 650-493-5000. TTY: 711."
                            )
                            LinkRow(
                                title: "3801 Miranda Avenue, Palo Alto, CA 94304",
                                systemImage: "map",
                                destination: "https://maps.apple.com/?q=VA%20Palo%20Alto%20Health%20Care%20System%203801%20Miranda%20Avenue%20Palo%20Alto%20CA%2094304"
                            )
                            LinkRow(
                                title: "VA Palo Alto website",
                                systemImage: "safari",
                                destination: "https://www.va.gov/palo-alto-health-care/"
                            )
                        }
                        .card(padded: false)
                    }
                }

                VStack(alignment: .leading, spacing: Space.half) {
                    SectionTitle("Privacy")
                    DividedStack {
                        PrivacyRow(
                            systemImage: "iphone",
                            title: "Your data stays on this phone",
                            message: "Your doses, pain scores and plan are saved on this phone with SwiftData, Apple's built-in storage. Nothing is copied anywhere else."
                        )
                        PrivacyRow(
                            systemImage: "person.crop.circle.badge.xmark",
                            title: "No account",
                            message: "You never sign up or log in. Bridge doesn't know who you are."
                        )
                        PrivacyRow(
                            systemImage: "eye.slash",
                            title: "No server, no tracking",
                            message: "Bridge has no server to send anything to. It has no analytics and no ads, and it doesn't track how you use it."
                        )
                        PrivacyRow(
                            systemImage: "square.and.arrow.up",
                            title: "You decide what's shared",
                            message: "The only way anything leaves your phone is when you tap Share on your doctor summary and pick where it goes."
                        )
                    }
                    .card(padded: false)
                    CardNote("If you back up your iPhone, the backup includes Bridge like any other app. That is a setting on your phone, not something Bridge does.")
                }
            }
            .navigationTitle("Support")
            .animation(.default, value: showsVeteranResources)
        }
    }
}

/// One plain-language privacy fact: an icon, a short heading and a sentence or two.
private struct PrivacyRow: View {
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: Space.unit) {
            Image(systemName: systemImage)
                .font(.bridge(.headline))
                .foregroundStyle(.tint)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Space.tight) {
                Text(title)
                    .font(.bridge(.headline))
                    .foregroundStyle(Color.textPrimary)
                Text(message)
                    .font(.bridge(.caption))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardRow()
        .accessibilityElement(children: .combine)
    }
}

/// A named phone number that starts a call when tapped.
private struct PhoneRow: View {
    let name: LocalizedStringKey
    /// How the number is shown, which may include dialing instructions.
    let number: LocalizedStringKey
    /// The `tel:` address that is dialed.
    let dialing: String
    let detail: LocalizedStringKey

    var body: some View {
        Link(destination: URL(string: dialing)!) {
            HStack(alignment: .top, spacing: Space.unit) {
                VStack(alignment: .leading, spacing: Space.tight) {
                    Text(name)
                        .font(.bridge(.headline))
                        .foregroundStyle(Color.textPrimary)
                    Text(number)
                        .font(.bridge(.title))
                        .foregroundStyle(.tint)
                    Text(detail)
                        .font(.bridge(.caption))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer(minLength: Space.half)
                Image(systemName: "phone.fill")
                    .font(.bridge(.headline))
                    .foregroundStyle(.tint)
                    .padding(.top, Space.tight)
            }
            .cardRow()
            .contentShape(Rectangle())
        }
        // Without this the link recolours its whole label in the accent colour,
        // which makes the small description text hard to read.
        .buttonStyle(.plain)
        .accessibilityLabel(Text(name) + Text(verbatim: ", ") + Text(number))
        .accessibilityHint("Starts a call")
    }
}

/// A row that opens a web page or Maps.
private struct LinkRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    let destination: String

    var body: some View {
        Link(destination: URL(string: destination)!) {
            Label {
                Text(title)
                    .font(.bridge(.body))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
            }
            .cardRow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SupportView()
}
