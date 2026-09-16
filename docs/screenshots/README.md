# Screenshots

Captured from the running app on the Android emulator (API 36, 1080×1920) with
the filter on at the Evening preset, English, dark theme. The tint in the shots is
the app's real overlay, not an edit. A temporary Pro pass was active so that
Google's test ads do not appear in them. The notification shade is drawn above
app overlays by Android, so that one shot is untinted.

They are not generated. Rendering the widgets headlessly would produce pictures
of the layout rather than of the app — no real panel, no real tint, and the
melanopic figures sitting on a screen nobody has looked at. For an app whose
whole claim is that its numbers are honest, a picture of numbers that were never
on a phone is the wrong first impression.

## What to capture

Portrait, on a phone, with the filter **on** so the tint is visible in the shot:

| File | Screen | Why this one |
|---|---|---|
| `home.png` | Home | The three axes and the melanopic ring — the app's argument in one image |
| `notification.png` | Shade, expanded | The cockpit, which is the feature people stay for |
| `education.png` | Eye health | Shows the sources, which is what separates this from the others |
| `schedule.png` | Schedule | The bedtime assistant with a fade set |
| `presets.png` | Presets | The grid, mid press-and-hold if you can catch it |

Take them at the device's own resolution and do not upscale. Play wants at least
320 px on the short edge and at most 3840 px on the long one; a modern phone
screenshot is already inside that.

Both themes are worth having if it is not much trouble — the light theme is the
one that was broken in 1.x, and showing it says it is fixed.

## What not to do

Do not paste them into a device frame or a marketing mock-up. The point is what
the app looks like, not what a render of a phone looks like.
