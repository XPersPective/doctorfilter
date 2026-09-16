/// What the app remembers about a user's exposure to ads.
///
/// Persisted, because the whole point of the policy is that it spans sessions.
final class AdPolicyState {
  const AdPolicyState({
    required this.firstLaunch,
    required this.sessionCount,
    this.lastInterstitialAt,
    this.interstitialsThisSession = 0,
    this.presetChangesThisSession = 0,
    this.rewardedViewsToday = 0,
    this.rewardedDay,
    this.lastAppOpenAt,
  });

  /// When the app was first opened. The grace period counts from here.
  final DateTime firstLaunch;

  /// How many times the app has been opened, this one included.
  final int sessionCount;

  final DateTime? lastInterstitialAt;
  final int interstitialsThisSession;
  final int presetChangesThisSession;

  /// Rewarded ads watched on [rewardedDay], for the daily cap.
  final int rewardedViewsToday;
  final DateTime? rewardedDay;

  /// When an app-open ad last appeared, across sessions.
  final DateTime? lastAppOpenAt;

  AdPolicyState copyWith({
    DateTime? firstLaunch,
    int? sessionCount,
    DateTime? lastInterstitialAt,
    int? interstitialsThisSession,
    int? presetChangesThisSession,
    int? rewardedViewsToday,
    DateTime? rewardedDay,
    DateTime? lastAppOpenAt,
  }) {
    return AdPolicyState(
      firstLaunch: firstLaunch ?? this.firstLaunch,
      sessionCount: sessionCount ?? this.sessionCount,
      lastInterstitialAt: lastInterstitialAt ?? this.lastInterstitialAt,
      interstitialsThisSession:
          interstitialsThisSession ?? this.interstitialsThisSession,
      presetChangesThisSession:
          presetChangesThisSession ?? this.presetChangesThisSession,
      rewardedViewsToday: rewardedViewsToday ?? this.rewardedViewsToday,
      rewardedDay: rewardedDay ?? this.rewardedDay,
      lastAppOpenAt: lastAppOpenAt ?? this.lastAppOpenAt,
    );
  }
}

/// Something the user just did that could reasonably be followed by an ad.
///
/// All of these are *ends* of an activity. An ad that interrupts something is an
/// uninstall; an ad that fills a gap the user was going to sit through anyway is
/// tolerable.
enum AdMoment {
  /// The user turned the filter off — they are done for now.
  filterDisabled,

  /// The user backed out of the presets screen.
  leftPresets,

  /// The user has been flicking between presets for a while.
  presetChurn,
}

/// Decides whether an interstitial may be shown.
///
/// Pure and side-effect free so the rules can be tested without an ad SDK,
/// a clock, or a device. Every limit here exists because the alternative is a
/// one-star review: the app is used at bedtime, by people whose eyes already
/// hurt, and a full-screen ad at that moment is unforgivable.
abstract final class AdPolicy {
  /// No interstitials at all for this long after install.
  ///
  /// Long enough to form a habit and decide the app is worth keeping. The banner
  /// is still there, so the app is visibly ad-supported from day one — this is
  /// breathing room, not a bait and switch.
  static const Duration gracePeriod = Duration(days: 3);

  /// ...and no interstitials until at least this many sessions have happened,
  /// whichever comes later. Someone who installs and opens the app twice a week
  /// gets the same grace as someone who opens it hourly.
  static const int graceSessions = 5;

  /// At most one interstitial per session, ever.
  static const int maxPerSession = 1;

  /// And never two closer together than this, even across sessions — an app
  /// that is opened and closed repeatedly must not turn into an ad machine.
  static const Duration minimumGap = Duration(minutes: 4);

  /// How much preset-flicking counts as "browsing" rather than "adjusting".
  static const int presetChurnThreshold = 4;

  /// Daily cap on rewarded ads. Two is enough for 48 hours of Pro passes, and
  /// past that the user should be buying rather than grinding.
  static const int maxRewardedPerDay = 2;

  /// Rewarded ads are not offered before this long after install.
  ///
  /// A free day of Pro on day one teaches that Pro is something you watch ads
  /// for. A week in, the user knows what the free version does and whether
  /// the rest is worth trying.
  static const Duration rewardedUnlockAfter = Duration(days: 7);

  /// Least time between two app-open ads. The app is opened most at bedtime,
  /// often more than once; an ad at every opening would be the one people
  /// remember.
  static const Duration appOpenGap = Duration(hours: 4);

  /// How long a rewarded ad buys.
  static const Duration rewardedPassDuration = Duration(hours: 24);

  /// Whether an interstitial may be shown right now.
  static bool mayShowInterstitial({
    required AdPolicyState state,
    required AdMoment moment,
    required bool isPro,
    required DateTime now,
  }) {
    // Pro means no ads. Not fewer ads, not smaller ads.
    if (isPro) return false;

    if (now.difference(state.firstLaunch) < gracePeriod) return false;
    if (state.sessionCount <= graceSessions) return false;

    if (state.interstitialsThisSession >= maxPerSession) return false;

    final last = state.lastInterstitialAt;
    if (last != null && now.difference(last) < minimumGap) return false;

    return switch (moment) {
      AdMoment.filterDisabled => true,
      AdMoment.leftPresets => true,
      // Only once the user is clearly browsing rather than dialling something in.
      AdMoment.presetChurn =>
        state.presetChangesThisSession >= presetChurnThreshold,
    };
  }

  /// Whether an app-open ad may be shown as the app starts.
  ///
  /// Same grace period as interstitials, and it spends the session's one
  /// full-screen ad: a user who saw one on the way in does not get another on
  /// the way out.
  static bool mayShowAppOpen({
    required AdPolicyState state,
    required bool isPro,
    required DateTime now,
  }) {
    if (isPro) return false;

    if (now.difference(state.firstLaunch) < gracePeriod) return false;
    if (state.sessionCount <= graceSessions) return false;

    if (state.interstitialsThisSession >= maxPerSession) return false;

    final lastInterstitial = state.lastInterstitialAt;
    if (lastInterstitial != null &&
        now.difference(lastInterstitial) < minimumGap) {
      return false;
    }

    final lastAppOpen = state.lastAppOpenAt;
    return lastAppOpen == null || now.difference(lastAppOpen) >= appOpenGap;
  }

  /// Whether the user may watch another rewarded ad today.
  static bool mayWatchRewarded({
    required AdPolicyState state,
    required bool isPro,
    required DateTime now,
  }) {
    // Nothing to earn — they already own everything.
    if (isPro) return false;
    if (now.difference(state.firstLaunch) < rewardedUnlockAfter) return false;
    if (!_isSameDay(state.rewardedDay, now)) return true;
    return state.rewardedViewsToday < maxRewardedPerDay;
  }

  /// Whether the banner should be on screen.
  static bool showBanner({required bool isPro}) => !isPro;

  static bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;
}
