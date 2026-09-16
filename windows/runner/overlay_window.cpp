#include "overlay_window.h"

#include <algorithm>

namespace {

constexpr wchar_t kWindowClass[] = L"DoctorFilterOverlay";

// Mirrors FilterConfig.maxCompositeAlpha (0.92). At 100% a layered window is a
// solid sheet the user cannot see through or click away, and on Windows there
// is no notification shade to rescue them from it.
constexpr BYTE kMaxAlpha = 235;

// The overlay is removed only by the app (stopOverlay, or the app closing).
// A stray WM_CLOSE — from a window-management tool, or anything that picks this
// as the process's "main" window — would otherwise destroy it while the app
// still says the filter is on.
LRESULT CALLBACK OverlayWndProc(HWND window, UINT message, WPARAM wparam,
                                LPARAM lparam) {
  if (message == WM_CLOSE) return 0;
  return DefWindowProcW(window, message, wparam, lparam);
}

bool EnsureClassRegistered() {
  static bool registered = false;
  if (registered) return true;

  WNDCLASSEXW window_class{};
  window_class.cbSize = sizeof(WNDCLASSEXW);
  window_class.lpfnWndProc = OverlayWndProc;
  window_class.hInstance = GetModuleHandleW(nullptr);
  window_class.lpszClassName = kWindowClass;
  window_class.hbrBackground = nullptr;

  registered = RegisterClassExW(&window_class) != 0 ||
               GetLastError() == ERROR_CLASS_ALREADY_EXISTS;
  return registered;
}

}  // namespace

OverlayWindow::OverlayWindow() = default;

OverlayWindow::~OverlayWindow() { Hide(); }

bool OverlayWindow::Show(int red, int green, int blue, int alpha) {
  colour_ = RGB(static_cast<BYTE>(std::clamp(red, 0, 255)),
                static_cast<BYTE>(std::clamp(green, 0, 255)),
                static_cast<BYTE>(std::clamp(blue, 0, 255)));
  alpha_ = static_cast<BYTE>(std::clamp(alpha, 0, static_cast<int>(kMaxAlpha)));

  if (window_ == nullptr) {
    if (!EnsureClassRegistered()) return false;

    // WS_EX_TRANSPARENT is what makes this a filter rather than a wall: mouse
    // input passes straight through to whatever is underneath.
    // WS_EX_NOACTIVATE keeps it from stealing focus, and WS_EX_TOOLWINDOW keeps
    // it out of the taskbar and Alt-Tab, where a full-screen tint would be
    // baffling.
    window_ = CreateWindowExW(
        WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOPMOST | WS_EX_NOACTIVATE |
            WS_EX_TOOLWINDOW,
        kWindowClass, L"", WS_POPUP, 0, 0, 0, 0, nullptr, nullptr,
        GetModuleHandleW(nullptr), nullptr);

    if (window_ == nullptr) return false;

    FitToVirtualScreen();
    ShowWindow(window_, SW_SHOWNOACTIVATE);
  }

  Paint();
  return true;
}

void OverlayWindow::Hide() {
  if (window_ == nullptr) return;
  DestroyWindow(window_);
  window_ = nullptr;
}

void OverlayWindow::FitToVirtualScreen() {
  const int left = GetSystemMetrics(SM_XVIRTUALSCREEN);
  const int top = GetSystemMetrics(SM_YVIRTUALSCREEN);
  const int width = GetSystemMetrics(SM_CXVIRTUALSCREEN);
  const int height = GetSystemMetrics(SM_CYVIRTUALSCREEN);

  SetWindowPos(window_, HWND_TOPMOST, left, top, width, height,
               SWP_NOACTIVATE | SWP_SHOWWINDOW);
}

void OverlayWindow::Paint() {
  if (window_ == nullptr) return;

  // Re-fit on every paint: a monitor may have been plugged in or the resolution
  // changed since the overlay went up, which would otherwise leave a bright
  // unfiltered band down one side.
  FitToVirtualScreen();

  // SetLayeredWindowAttributes rather than UpdateLayeredWindow: the whole
  // window is one flat colour, so there is no bitmap worth compositing.
  SetLayeredWindowAttributes(window_, 0, alpha_, LWA_ALPHA);

  HDC device_context = GetDC(window_);
  if (device_context == nullptr) return;

  RECT client{};
  GetClientRect(window_, &client);

  HBRUSH brush = CreateSolidBrush(colour_);
  FillRect(device_context, &client, brush);
  DeleteObject(brush);

  ReleaseDC(window_, device_context);
}
