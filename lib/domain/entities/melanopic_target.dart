/// Where the current settings sit against the evening lighting guidance.
///
/// Brown et al. (2022, PLOS Biology) put the evening target at **≤10 lx
/// melanopic EDI** at the eye. The app cannot measure that: absolute melanopic
/// EDI depends on the panel, the brightness setting and how far away the user
/// is holding the phone, none of which are knowable from inside an app. Section
/// 5.6 is explicit that no absolute lx figure may be claimed.
///
/// So the app works in **relative reduction** and states the one assumption it
/// makes out loud, rather than inventing a number and calling it a measurement.
abstract final class MelanopicTarget {
  /// The reduction taken to represent "at the evening guidance".
  ///
  /// Reported measurements of phones at typical evening brightness, held at
  /// reading distance, land in the region of 20–40 lx melanopic EDI. Getting
  /// from there to ≤10 lx needs roughly a two-thirds to three-quarters cut, so
  /// 70% is the midpoint of that range.
  ///
  /// This is an **assumption, not a measurement**, and the UI says so. It exists
  /// to give the user a sense of direction — further round the ring is closer to
  /// the guidance — not to certify that any particular screen has reached it.
  static const double eveningReduction = 0.70;

  /// Where the screen is on the way to that target, 0.0–1.0.
  static double progress(double melanopicReduction) =>
      (melanopicReduction / eveningReduction).clamp(0.0, 1.0);

  /// Whether the settings are at or past the evening guidance.
  static bool meetsEvening(double melanopicReduction) =>
      melanopicReduction >= eveningReduction;
}
