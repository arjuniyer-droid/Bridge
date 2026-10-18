//
//  Motion.swift
//  Bridge
//

import SwiftUI
import UIKit

// How things move in Bridge. Everything is slow, soft and small: a settle, a
// fade, a growth. Nothing bounces past where it ends up and nothing is
// decorative. With Reduce Motion on, the animations are skipped and the screen
// simply shows the result.

enum Motion {
    /// A list making room for a new row. The short delay lets a sheet that is
    /// closing get out of the way first, so the new row is seen arriving.
    static let settle = Animation.spring(response: 0.5, dampingFraction: 0.85).delay(0.25)
    /// One screen replacing another.
    static let fade = Animation.easeOut(duration: 0.25)
    /// Chart bars rising from the baseline.
    static let grow = Animation.easeOut(duration: 0.7)
}

enum Haptics {
    /// A light tap for a saved dose or plan.
    static func saved() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

private struct CalmAnimation<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: Value

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

/// Fades a screen in each time it is shown, which is what moving between tabs
/// looks like. TabView swaps tabs instantly on its own.
private struct FadeInOnAppear: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var opacity = 1.0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                guard !reduceMotion else { return }
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { opacity = 0 }
                withAnimation(Motion.fade) { opacity = 1 }
            }
    }
}

extension View {
    /// `animation(_:value:)` that stands down when Reduce Motion is on.
    func calmAnimation<Value: Equatable>(_ animation: Animation, value: Value) -> some View {
        modifier(CalmAnimation(animation: animation, value: value))
    }

    func fadeInOnAppear() -> some View {
        modifier(FadeInOnAppear())
    }
}
