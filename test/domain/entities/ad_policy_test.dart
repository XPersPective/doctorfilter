import 'package:flutter_test/flutter_test.dart';
import 'package:doctorfilter/domain/entities/ad_policy.dart';

final _now = DateTime(2026, 6, 15, 22, 0);

/// A user well past the grace period, with no ad shown yet this session.
AdPolicyState eligible({
  int sessions = 20,
  DateTime? lastInterstitial,
  int shownThisSession = 0,
  int presetChanges = 0,
  int rewardedToday = 0,
  DateTime? rewardedDay,
  DateTime? lastAppOpen,
}) =>
    AdPolicyState(
      firstLaunch: _now.subtract(const Duration(days: 30)),
      sessionCount: sessions,
      lastInterstitialAt: lastInterstitial,
      interstitialsThisSession: shownThisSession,
      presetChangesThisSession: presetChanges,
      rewardedViewsToday: rewardedToday,
      rewardedDay: rewardedDay,
      lastAppOpenAt: lastAppOpen,
    );

bool allowed(
  AdPolicyState state, {
  AdMoment moment = AdMoment.filterDisabled,
  bool isPro = false,
}) =>
    AdPolicy.mayShowInterstitial(
      state: state,
      moment: moment,
      isPro: isPro,
      now: _now,
    );

void main() {
  group('Pro means no ads — not fewer ads', () {
    test('an entitled user never sees an interstitial', () {
      expect(allowed(eligible(), isPro: true), isFalse);
    });

    test('an entitled user has no banner', () {
      expect(AdPolicy.showBanner(isPro: true), isFalse);
      expect(AdPolicy.showBanner(isPro: false), isTrue);
    });

    test('an entitled user is not offered rewarded ads either', () {
      expect(
        AdPolicy.mayWatchRewarded(state: eligible(), isPro: true, now: _now),
        isFalse,
      );
    });
  });

  group('the grace period — a new user is left alone', () {
    test('nothing on day one, however many sessions', () {
      final fresh = AdPolicyState(
        firstLaunch: _now.subtract(const Duration(hours: 2)),
        sessionCount: 50,
      );
      expect(allowed(fresh), isFalse);
    });

    test('nothing in the first few sessions, however many days', () {
      final occasional = AdPolicyState(
        firstLaunch: _now.subtract(const Duration(days: 60)),
        sessionCount: AdPolicy.graceSessions,
      );
      expect(allowed(occasional), isFalse,
          reason: 'someone who opens the app weekly deserves the same grace');
    });

    test('both conditions must pass, not either', () {
      final justOverBoth = AdPolicyState(
        firstLaunch: _now.subtract(AdPolicy.gracePeriod + const Duration(hours: 1)),
        sessionCount: AdPolicy.graceSessions + 1,
      );
      expect(allowed(justOverBoth), isTrue);
    });
  });

  group('frequency caps', () {
    test('one interstitial per session and no more', () {
      expect(allowed(eligible(shownThisSession: 1)), isFalse);
    });

    test('two ads can never land closer than the minimum gap', () {
      final justShown = eligible(
        lastInterstitial: _now.subtract(const Duration(minutes: 1)),
      );
      expect(allowed(justShown), isFalse,
          reason: 'closing and reopening must not become an ad machine');
    });

    test('past the gap, a new session is eligible again', () {
      final earlier = eligible(
        lastInterstitial: _now.subtract(AdPolicy.minimumGap * 2),
      );
      expect(allowed(earlier), isTrue);
    });
  });

  group('natural pause points only', () {
    test('turning the filter off is a pause point', () {
      expect(allowed(eligible(), moment: AdMoment.filterDisabled), isTrue);
    });

    test('leaving the presets screen is a pause point', () {
      expect(allowed(eligible(), moment: AdMoment.leftPresets), isTrue);
    });

    test('changing a preset once or twice is adjusting, not browsing', () {
      expect(
        allowed(eligible(presetChanges: 2), moment: AdMoment.presetChurn),
        isFalse,
      );
    });

    test('flicking through several is browsing, and may be interrupted', () {
      expect(
        allowed(
          eligible(presetChanges: AdPolicy.presetChurnThreshold),
          moment: AdMoment.presetChurn,
        ),
        isTrue,
      );
    });
  });

  group('rewarded ads are capped per day', () {
    test('a fresh day resets the count', () {
      final yesterday = eligible(
        rewardedToday: AdPolicy.maxRewardedPerDay,
        rewardedDay: _now.subtract(const Duration(days: 1)),
      );
      expect(
        AdPolicy.mayWatchRewarded(state: yesterday, isPro: false, now: _now),
        isTrue,
      );
    });

    test('the daily cap holds within the same day', () {
      final maxedOut = eligible(
        rewardedToday: AdPolicy.maxRewardedPerDay,
        rewardedDay: _now,
      );
      expect(
        AdPolicy.mayWatchRewarded(state: maxedOut, isPro: false, now: _now),
        isFalse,
      );
    });

    test('under the cap is still allowed', () {
      final once = eligible(rewardedToday: 1, rewardedDay: _now);
      expect(
        AdPolicy.mayWatchRewarded(state: once, isPro: false, now: _now),
        isTrue,
      );
    });
  });

  group('app-open ads', () {
    bool appOpen(AdPolicyState state, {bool isPro = false}) =>
        AdPolicy.mayShowAppOpen(state: state, isPro: isPro, now: _now);

    test('allowed for an established user who has not seen one lately', () {
      expect(appOpen(eligible()), isTrue);
    });

    test('never for Pro', () {
      expect(appOpen(eligible(), isPro: true), isFalse);
    });

    test('never in the first days, however often the app is opened', () {
      final fresh = AdPolicyState(
        firstLaunch: _now.subtract(const Duration(days: 2)),
        sessionCount: 40,
      );
      expect(appOpen(fresh), isFalse);
    });

    test('never before enough sessions, however old the install', () {
      expect(appOpen(eligible(sessions: AdPolicy.graceSessions)), isFalse);
    });

    test('shares the session budget with interstitials', () {
      expect(appOpen(eligible(shownThisSession: 1)), isFalse);
    });

    test('not again within the gap', () {
      final recent = eligible(
        lastAppOpen: _now.subtract(AdPolicy.appOpenGap - const Duration(minutes: 1)),
      );
      expect(appOpen(recent), isFalse);
      final later = eligible(lastAppOpen: _now.subtract(AdPolicy.appOpenGap));
      expect(appOpen(later), isTrue);
    });
  });

  group('rewarded pass unlocks a week after install', () {
    test('not offered on day six', () {
      final young = AdPolicyState(
        firstLaunch: _now.subtract(const Duration(days: 6)),
        sessionCount: 30,
      );
      expect(
        AdPolicy.mayWatchRewarded(state: young, isPro: false, now: _now),
        isFalse,
      );
    });

    test('offered from day seven', () {
      final week = AdPolicyState(
        firstLaunch: _now.subtract(AdPolicy.rewardedUnlockAfter),
        sessionCount: 1,
      );
      expect(
        AdPolicy.mayWatchRewarded(state: week, isPro: false, now: _now),
        isTrue,
      );
    });
  });
}
