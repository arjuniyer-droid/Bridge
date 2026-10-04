//
//  NewDay.swift
//  Bridge
//

import SwiftUI

extension Date {
    /// The start of the current calendar day. Every screen that depends on
    /// "today" reads it from here, so the day is worked out in one place.
    static var startOfToday: Date {
        Calendar.current.startOfDay(for: .now)
    }
}

/// Runs an action when the calendar day changes while the app is running,
/// whenever the app comes back to the foreground (the day may have changed
/// while it was suspended, and no notification is delivered then), and whenever
/// the view appears. The last one covers a tab that wasn't on screen when the
/// day changed, which never receives the other two until it is shown again.
private struct OnNewDay: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear(perform: action)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { action() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                action()
            }
    }
}

extension View {
    /// Calls `action` when the day rolls over, the app returns to the
    /// foreground, or the view appears. Use it to refresh anything that depends
    /// on today's date.
    func onNewDay(_ action: @escaping () -> Void) -> some View {
        modifier(OnNewDay(action: action))
    }
}
