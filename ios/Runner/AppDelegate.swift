import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let channelName = "com.crazypenguin.doctorfilter"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerChannel(with: engineBridge.binaryMessenger)
  }

  /// The iOS side of the platform channel.
  ///
  /// Deliberately small. iOS has no equivalent of Android's overlay window and
  /// no way for an app to move the Accessibility sliders, so most of the
  /// channel's Android methods have no iOS counterpart and are answered as
  /// unimplemented rather than faked — a method that silently does nothing is
  /// how an app ends up claiming something it cannot do.
  ///
  /// What *is* real here is screen brightness: `UIScreen.brightness` is the
  /// system brightness, and a change made from inside the app survives leaving
  /// it. That is the honest iOS counterpart of the extra-dim axis.
  private func registerChannel(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: AppDelegate.channelName, binaryMessenger: messenger)

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getScreenBrightness":
        result(Double(UIScreen.main.brightness))

      case "setScreenBrightness":
        guard
          let arguments = call.arguments as? [String: Any],
          let value = arguments["brightness"] as? Double
        else {
          result(FlutterError(code: "bad_arguments",
                              message: "brightness (0.0–1.0) is required",
                              details: nil))
          return
        }
        UIScreen.main.brightness = CGFloat(min(max(value, 0.0), 1.0))
        result(true)

      // Asked on every platform so Dart can branch without a platform check of
      // its own; on iOS the answer is simply no.
      case "checkOverlayPermission", "isFilterRunning", "isBatteryOptimised",
           "canScheduleExactAlarms", "hasUsageAccess":
        result(false)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
