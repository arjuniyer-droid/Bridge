//
//  OnboardingView.swift
//  Bridge
//

import SwiftUI

/// Three short screens shown once, the first time Bridge opens: what it does,
/// where the data lives, and that it never gives medical advice.
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0
    @Environment(\.accentWash) private var accentWash

    private struct Page {
        let systemImage: String
        let title: LocalizedStringKey
        let message: LocalizedStringKey
    }

    private let pages = [
        Page(
            systemImage: "pills",
            title: "Welcome to Bridge",
            message: "Bridge helps you log your doses and pain, so you and your prescriber can see how you're doing."
        ),
        Page(
            systemImage: "lock.iphone",
            title: "Everything stays on this phone",
            message: "No account and no cloud. Nothing is shared until you share it."
        ),
        Page(
            systemImage: "stethoscope",
            title: "No medical advice",
            message: "Bridge never gives medical advice. Your prescriber is the only authority."
        ),
    ]

    private var isLast: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPage(
                        systemImage: pages[index].systemImage,
                        title: pages[index].title,
                        message: pages[index].message
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // The page dots are drawn here, in the accent colour, rather than
            // by TabView, whose dots are grey and hard to see.
            HStack(spacing: Space.half) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(index == page ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.hairline))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, Space.unit)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(page + 1) of \(pages.count)")

            Button {
                if isLast {
                    onFinish()
                } else {
                    withAnimation(Motion.fade) { page += 1 }
                }
            } label: {
                Text(LocalizedStringKey(isLast ? "Get Started" : "Continue"))
            }
            .buttonStyle(.bridgePrimary)
            .padding(.horizontal, Space.unit)
            .padding(.bottom, Space.unit)
        }
        .background(Color.screenBackground.ignoresSafeArea())
    }
}

private struct OnboardingPage: View {
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    @Environment(\.accentWash) private var accentWash
    @ScaledMetric(relativeTo: .largeTitle) private var badgeSize = 112.0

    var body: some View {
        ScrollView {
            VStack(spacing: Space.unit + Space.half) {
                Image(systemName: systemImage)
                    .font(.system(size: badgeSize * 0.42, weight: .regular))
                    .foregroundStyle(.tint)
                    .frame(width: badgeSize, height: badgeSize)
                    .background(accentWash, in: Circle())
                    .padding(.bottom, Space.unit)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.bridge(.title))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(.bridge(.body))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Space.double)
            // The same distance from the top on every page, so the icon
            // doesn't shift as you move between them. It scrolls when large
            // text makes a page taller than the screen.
            .padding(.top, Space.double * 5)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

#Preview {
    OnboardingView {}
}
