import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/presentation/providers/ad_providers.dart';

/// Plays a rewarded ad and grants the Pro pass if it was watched to the end.
///
/// Shared by the paywall and the home screen's app-bar button, so both say the
/// same thing and follow the same rule: the reward is only granted for a
/// finished ad — AdMob requires that, and anything else makes the button a lie.
/// Returns whether the pass was granted.
Future<bool> watchAdForProPass(BuildContext context, WidgetRef ref) async {
  final policy = ref.read(adPolicyProvider.notifier);
  if (!policy.mayWatchRewarded) return false;

  final messenger = ScaffoldMessenger.of(context);
  final loc = AppLocalizations.of(context);

  final ads = ref.read(rewardedAdManagerProvider);
  // Bounded: if the SDK was never started this session (the app opened while
  // a pass was still running), waiting for it would spin forever.
  await ads.preload().timeout(const Duration(seconds: 15), onTimeout: () {});
  final earned = await ads.showForReward();

  if (!earned) {
    messenger.showSnackBar(SnackBar(
      content: Text(loc?.translate('reward_not_earned') ??
          'The ad was not finished, so no pass was given.'),
    ));
    return false;
  }

  await policy.recordRewardedWatched();
  messenger.showSnackBar(SnackBar(
    content: Text(
        loc?.translate('reward_granted') ?? 'Pro is unlocked for 24 hours. Enjoy.'),
  ));
  return true;
}
