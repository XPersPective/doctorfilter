# Privacy policy

**Last updated:** 15 September 2026
**Applies to:** DoctorFilter (`com.crazypenguin.doctorfilter`)

## The short version

DoctorFilter has no account, no server and no analytics. Your settings live on
your device and nowhere else. Nobody — including the developer — can see how you
use the app.

## What the app stores

All of it on your device only, and all of it deleted when you uninstall:

- Your filter settings: colour temperature, filter density, extra dim.
- Your presets, including any you create.
- Your schedule times.
- Your language and theme choice.
- Whether you have purchased Pro, and when a trial pass expires.
- Two counters used to keep ads infrequent: when you first launched the app, and
  how many times you have opened it.

None of this is transmitted anywhere.

## What the app does not do

- It does not read, record or transmit anything on your screen. It only draws a
  coloured layer on top, which is what the "display over other apps" permission
  is for.
- It has no analytics, telemetry or crash-reporting SDK.
- It does not collect your name, email, location, contacts, device identifiers
  or advertising ID for its own purposes.
- It has no backend server to send data to.

## Third parties

Two, and only in the situations described.

### Google AdMob — free version only

The free version shows advertising, which is provided by Google AdMob. To serve
ads, Google may process the advertising identifier on your device along with
technical information such as device type, coarse location derived from your IP
address, and interaction with the ads themselves.

- In the EEA, the UK and Switzerland you are asked for consent through Google's
  own consent form before any ad is requested. Declining personalised ads means
  you see non-personalised ones instead.
- On iOS you are asked separately, through Apple's App Tracking Transparency
  prompt, before the advertising identifier can be used.
- **If you purchase Pro, the ad SDK is never initialised at all.** It is not
  started and silenced — it does not run.

Google's handling of this data is governed by its own policy:
<https://policies.google.com/privacy>

### Your app store — only when you buy Pro

Purchases go through Google Play or the App Store. They handle the payment; the
app receives only a confirmation that a purchase exists. The developer never
sees your payment details, and the app never asks for them.

## Permissions, and why

| Permission | Why |
|---|---|
| Display over other apps | To draw the filter on top of whatever you are using. Nothing is read from the screen. |
| Post notifications | To show the control notification while the filter runs. |
| Foreground service | Android requires one to keep the filter drawn while you use other apps. |
| Exact alarm | So the schedule starts at the time you set rather than minutes later. |
| Boot completed | To restore your schedule, and the filter itself, after a restart. |
| Internet | Used only by the advertising SDK and store purchases. |

## Children

The app is not directed at children and collects no personal data. Advertising
served in the free version is subject to Google's own policies for family
content.

## Your rights

Since no personal data leaves your device, there is nothing held about you to
access, correct or delete remotely. Removing everything the app has stored is a
matter of uninstalling it.

## Verifying this

DoctorFilter is open source under GPL-3.0. Every claim on this page can be
checked against the code:

<https://github.com/XPersPective/doctorfilter>

## Changes

Material changes to this policy will be published in this file and noted in the
app's release notes.

## Contact

Open an issue at <https://github.com/XPersPective/doctorfilter/issues>.

---

## Notes for the Play Data Safety and App Privacy forms

*Not part of the policy — a record of what has been declared and why, so the
answers stay consistent across releases.*

- **Data collected:** none by the app itself.
- **Data shared:** none by the app itself.
- **Third-party SDK (free version only):** Google AdMob, which collects the
  advertising ID and approximate location for advertising purposes. Declare
  under "Device or other IDs" and "Location → Approximate location", purpose
  "Advertising or marketing", shared: yes, optional: no (free tier), user can
  request deletion: via device ad-ID controls.
- **Purchases:** handled by the store; no payment data reaches the app.
- **Encryption in transit:** yes, by the SDKs used.
- **Data deletion:** uninstalling removes everything local.
