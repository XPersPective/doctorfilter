import AppIntents
import SwiftUI
import WidgetKit

/// Control Centre and Lock Screen control (iOS 18+).
///
/// What this can and cannot do, so nobody is tempted to promise more:
///
/// * It **cannot** switch iOS's Colour Filters. No public API sets that, from a
///   control or from anywhere else. Section 7.2.4 forbids implying otherwise.
/// * It **can** run a Shortcut, and Shortcuts *does* have a Colour Filters
///   action. So the control triggers the user's own shortcut — the same route
///   the in-app button uses.
///
/// The one-line difference from the in-app button is that this needs no app:
/// swipe down, tap, done.
@available(iOS 18.0, *)
struct DoctorFilterControl: ControlWidget {
    static let kind = "com.crazypenguin.doctorfilter.control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: RunFilterShortcutIntent()) {
                Label("DoctorFilter", systemImage: "moon.circle")
            }
        }
        .displayName("DoctorFilter")
        .description("Runs your DoctorFilter shortcut.")
    }
}

/// Opens the `shortcuts://` URL that runs the user's shortcut.
///
/// `openAppWhenRun` is true because a control cannot open a third-party URL by
/// itself; the app is brought forward for the instant it takes to hand the URL
/// to Shortcuts. That hop is visible, and the app's own text says so rather
/// than leaving the user to think something broke.
@available(iOS 18.0, *)
struct RunFilterShortcutIntent: AppIntent {
    static let title: LocalizedStringResource = "Run DoctorFilter shortcut"

    /// Matches `_shortcutName` in `ios_setup_screen.dart`. One fixed name the
    /// setup instructions can quote; renaming a shortcut is two taps.
    static let shortcutName = "DoctorFilter"

    static var openAppWhenRun: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        let encoded = Self.shortcutName
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            ?? Self.shortcutName

        guard let url = URL(
            string: "shortcuts://x-callback-url/run-shortcut?name=\(encoded)"
        ) else {
            return .result(opensIntent: OpenURLIntent(URL(string: "doctorfilter://")!))
        }

        return .result(opensIntent: OpenURLIntent(url))
    }
}

@available(iOS 18.0, *)
@main
struct DoctorFilterControlBundle: WidgetBundle {
    var body: some Widget {
        DoctorFilterControl()
    }
}
