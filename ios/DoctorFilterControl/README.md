# DoctorFilter Control (iOS 18+ Control Centre)

`DoctorFilterControl.swift` is finished, but **it is not yet part of the Xcode
project**. A widget extension is a separate build target, and a target cannot be
created safely by editing `project.pbxproj` by hand — one wrong UUID or a missing
build phase breaks the whole iOS build, and that damage is invisible until
someone tries to compile on a Mac.

So the source lives here and the target gets added in Xcode, once, in about two
minutes.

## Adding the target

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Widget Extension.**
   - Product Name: `DoctorFilterControl`
   - Uncheck *Include Live Activity* and *Include Configuration App Intent* —
     both add scaffolding this control does not use.
   - Embed in Application: `Runner`.
3. Xcode creates a folder with a placeholder widget. Delete its generated
   `.swift` files and drag `DoctorFilterControl.swift` from this folder in,
   ticking the `DoctorFilterControl` target only (**not** `Runner`).
4. Set the extension's **Minimum Deployment** to iOS 18.0. The control APIs do
   not exist before that, and the `@available` attributes alone will not build
   against an older target.
5. Build and run on a device with iOS 18 or later.

## Verifying it

- Swipe down for Control Centre → **+** → add **DoctorFilter**.
- Tapping it should briefly show the app, then Shortcuts, then return.
- With no shortcut named `DoctorFilter`, Shortcuts reports it cannot find one.
  That is the correct outcome, not a bug in the control.

## What it deliberately does not do

It does not switch Colour Filters directly. No public API does, from a control
or anywhere else — the control runs the user's Shortcut, and Shortcuts is what
has the Colour Filters action. See the iOS-limits row in §6 of `PROJECT_BRAIN.md`: nothing in this app or
its store listing may imply that an app can set that filter itself.
