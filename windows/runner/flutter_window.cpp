#include "flutter_window.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "store_purchases.h"

namespace {

constexpr char kChannelName[] = "com.crazypenguin.doctorfilter";

int IntArgument(const flutter::EncodableMap& arguments, const char* key,
                int fallback) {
  const auto entry = arguments.find(flutter::EncodableValue(key));
  if (entry == arguments.end()) return fallback;
  if (const auto* value = std::get_if<int32_t>(&entry->second)) return *value;
  if (const auto* value = std::get_if<double>(&entry->second)) {
    return static_cast<int>(*value);
  }
  return fallback;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  RegisterFilterChannel();
  RegisterStorePurchases(flutter_controller_->engine()->messenger(), GetHandle());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

// The Windows side of the platform channel.
//
// Windows, unlike iOS, does let an app tint the whole screen, so the filter
// behaves the way it does on Android: the Dart layer sends an already-composited
// colour and alpha, and this paints them. The axes, and the caps that keep the
// screen readable, stay in one unit-tested place rather than being recomputed
// per platform.
void FlutterWindow::RegisterFilterChannel() {
  auto channel = std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string& method = call.method_name();

        if (method == "startOverlay" || method == "updateOverlay") {
          const auto* arguments =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (arguments == nullptr) {
            result->Error("bad_arguments", "colour and alpha are required");
            return;
          }
          const bool shown = overlay_.Show(IntArgument(*arguments, "red", 255),
                                           IntArgument(*arguments, "green", 190),
                                           IntArgument(*arguments, "blue", 122),
                                           IntArgument(*arguments, "alpha", 0));
          result->Success(flutter::EncodableValue(shown));
          return;
        }

        if (method == "stopOverlay") {
          overlay_.Hide();
          result->Success(flutter::EncodableValue(true));
          return;
        }

        if (method == "isFilterRunning") {
          result->Success(flutter::EncodableValue(overlay_.is_visible()));
          return;
        }

        // Windows needs no permission to put a layered window on top, so the
        // answer is a plain yes rather than a prompt the user cannot act on.
        if (method == "checkOverlayPermission" ||
            method == "requestOverlayPermission") {
          result->Success(flutter::EncodableValue(true));
          return;
        }

        // Android-only questions. Answered rather than left to time out, but
        // never faked into a yes: a false here is the truth, not a stub.
        if (method == "isBatteryOptimised" || method == "canScheduleExactAlarms" ||
            method == "hasUsageAccess") {
          result->Success(flutter::EncodableValue(false));
          return;
        }

        result->NotImplemented();
      });
}

void FlutterWindow::OnDestroy() {
  // Before anything else: a tint left on the desktop after the app is gone is
  // the worst failure this window has, and there would be nothing left to
  // remove it.
  overlay_.Hide();

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
