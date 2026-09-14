/// Defines how the automatic filter scheduling behaves.
enum CircadianMode {
  /// Schedules based on fixed user-selected start and stop times.
  manualTime,

  /// Automatically calculates local sunset and sunrise for optimal circadian rhythm.
  sunsetToSunrise,
}
