#ifndef RUNNER_OVERLAY_WINDOW_H_
#define RUNNER_OVERLAY_WINDOW_H_

#include <windows.h>

// The Windows counterpart of the Android overlay service.
//
// A layered, click-through, always-on-top window covering every monitor. Unlike
// iOS, Windows does allow an app to tint the whole screen, so the filter here
// works the way it does on Android rather than needing a setup wizard.
//
// Deliberately a plain window rather than a plugin: it is one window with three
// operations, and a plugin package for that would be more machinery than the
// problem has.
class OverlayWindow {
 public:
  OverlayWindow();
  ~OverlayWindow();

  // Shows the overlay, or repaints it if already shown. Alpha is 0-255 and is
  // capped so the screen can never be painted solid — the same ceiling the Dart
  // entity enforces, repeated here as a second line of defence.
  bool Show(int red, int green, int blue, int alpha);

  void Hide();

  bool is_visible() const { return window_ != nullptr; }

 private:
  // Resizes to the union of every monitor, so a second screen is covered too.
  void FitToVirtualScreen();

  void Paint();

  HWND window_ = nullptr;
  COLORREF colour_ = RGB(255, 190, 122);
  BYTE alpha_ = 0;
};

#endif  // RUNNER_OVERLAY_WINDOW_H_
