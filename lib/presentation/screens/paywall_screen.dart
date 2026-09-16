import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/presentation/ads/rewarded_pass.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/domain/repositories/i_purchase_repository.dart';
import 'package:doctorfilter/domain/entities/ad_policy.dart';
import 'package:doctorfilter/presentation/providers/ad_providers.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';
import 'package:doctorfilter/presentation/providers/pro_provider.dart';

/// The Pro upgrade screen.
///
/// Sells one thing, once. No subscription, no tiers, no countdown timer, no
/// fake discount — a screen-comfort tool that pressures people at bedtime has
/// the wrong idea of what it is for.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isPro = ref.watch(isProProvider);
    final store = ref.watch(purchaseRepositoryProvider);
    final offer = ref.watch(proOfferProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc?.translate('pro_title') ?? 'DoctorFilter Pro'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _Header(isPro: isPro),
            const SizedBox(height: 24),
            ..._benefits(loc).map(
              (benefit) => _BenefitTile(
                icon: benefit.icon,
                title: benefit.title,
                detail: benefit.detail,
              ),
            ),
            const SizedBox(height: 24),
            if (isPro)
              _OwnedNotice(loc: loc)
            else if (!store.isAvailable)
              _UnavailableNotice(loc: loc)
            else
              _PurchaseSection(
                loc: loc,
                busy: _busy,
                price: offer.maybeWhen(
                  data: (value) => value?.formattedPrice,
                  orElse: () => null,
                ),
                onBuy: _buy,
                onRestore: _restore,
              ),
            if (!isPro && ref.watch(adPolicyProvider.notifier).mayWatchRewarded)
              _TryProSection(loc: loc, busy: _busy, onWatch: _watchForPass),
            const SizedBox(height: 16),
            Text(
              loc?.translate('pro_no_subscription_note') ??
                  'One payment, yours forever. DoctorFilter has no subscriptions '
                      'and no account — your settings never leave this device.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<({IconData icon, String title, String detail})> _benefits(
    AppLocalizations? loc,
  ) =>
      [
        (
          icon: Icons.block_rounded,
          title: loc?.translate('pro_benefit_no_ads_title') ?? 'No ads at all',
          detail: loc?.translate('pro_benefit_no_ads_detail') ??
              'Every ad disappears, including the banner.',
        ),
        (
          icon: Icons.notifications_active_rounded,
          title: loc?.translate('pro_benefit_notification_title') ??
              'Full control from the notification',
          detail: loc?.translate('pro_benefit_notification_detail') ??
              'Switch between every preset and adjust all three axes without '
                  'opening the app.',
        ),
        (
          icon: Icons.tune_rounded,
          title: loc?.translate('pro_benefit_presets_title') ??
              'Unlimited custom presets',
          detail: loc?.translate('pro_benefit_presets_detail') ??
              'Build and reorder as many profiles as you like.',
        ),
        (
          icon: Icons.schedule_rounded,
          title: loc?.translate('pro_benefit_schedule_title') ??
              'Multiple schedules',
          detail: loc?.translate('pro_benefit_schedule_detail') ??
              'Different filters for weeknights, weekends and shift work.',
        ),
      ];

  Future<void> _buy() async {
    setState(() => _busy = true);
    final result = await ref.read(purchaseRepositoryProvider).buyLifetime();
    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (_) => _say('error_store_unavailable', 'The store is not reachable right now.'),
      (outcome) => _handle(outcome),
    );
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final result = await ref.read(purchaseRepositoryProvider).restorePurchases();
    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (_) => _say('error_store_unavailable', 'The store is not reachable right now.'),
      (outcome) => _handle(outcome),
    );
  }

  void _handle(PurchaseOutcome outcome) {
    switch (outcome) {
      case PurchaseOutcome.purchased:
      case PurchaseOutcome.restored:
        // Entitlement arrives through the store stream; this only closes the
        // screen once it has.
        ref.read(proStatusProvider.notifier).grantLifetime();
        if (mounted) Navigator.pop(context);

      // Backing out is a choice, not a failure. Saying anything here would be
      // nagging someone who just said no.
      case PurchaseOutcome.cancelled:
        break;

      case PurchaseOutcome.pending:
        _say('purchase_pending',
            'Your purchase is being processed. Pro unlocks as soon as it clears.');

      case PurchaseOutcome.nothingToRestore:
        _say('purchase_nothing_to_restore',
            'No previous purchase was found on this account.');

      case PurchaseOutcome.unavailable:
        _say('error_store_unavailable', 'The store is not reachable right now.');
    }
  }

  /// Trades one ad for a day of Pro.
  ///
  /// Entirely opt-in, from a button that states the deal plainly. The reward is
  /// only granted if the ad was actually watched to the end — AdMob requires
  /// that, and granting it to someone who closed the ad early would make the
  /// button a lie.
  Future<void> _watchForPass() async {
    setState(() => _busy = true);
    final granted = await watchAdForProPass(context, ref);
    if (!mounted) return;
    setState(() => _busy = false);
    if (granted) Navigator.pop(context);
  }

  void _say(String key, String fallback) {
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc?.translate(key) ?? fallback)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primaryContainer,
          ),
          child: Icon(
            Icons.workspace_premium_rounded,
            size: 38,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isPro
              ? (loc?.translate('pro_owned_title') ?? 'You have Pro')
              : (loc?.translate('pro_headline') ?? 'Unlock everything, once'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseSection extends StatelessWidget {
  const _PurchaseSection({
    required this.loc,
    required this.busy,
    required this.price,
    required this.onBuy,
    required this.onRestore,
  });

  final AppLocalizations? loc;
  final bool busy;
  final String? price;
  final Future<void> Function() onBuy;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        FilledButton(
          onPressed: busy ? null : onBuy,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              // The price comes straight from the store, already in the user's
              // currency. While it loads the button still says what it does.
              : Text(
                  price == null
                      ? (loc?.translate('pro_upgrade_btn') ?? 'Get Pro')
                      : '${loc?.translate('pro_upgrade_btn') ?? 'Get Pro'} · $price',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : onRestore,
          child: Text(loc?.translate('pro_restore_btn') ?? 'Restore purchase'),
        ),
        Text(
          loc?.translate('pro_payment_note') ??
              'Paid through your app store, with the payment method already on '
                  'your account.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The try-before-you-buy offer.
///
/// Sits below the purchase button on purpose: buying is the main path, and this
/// is for the user who is not ready to decide. Hidden once the daily cap is
/// reached rather than shown greyed out — an offer that cannot be taken is just
/// clutter on a screen that is asking for money.
class _TryProSection extends StatelessWidget {
  const _TryProSection({
    required this.loc,
    required this.busy,
    required this.onWatch,
  });

  final AppLocalizations? loc;
  final bool busy;
  final Future<void> Function() onWatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = '${AdPolicy.rewardedPassDuration.inHours}';

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: OutlinedButton.icon(
        onPressed: busy ? null : onWatch,
        icon: const Icon(Icons.play_circle_outline_rounded),
        label: Text(
          loc?.translate('pro_try_with_ad', args: {'hours': hours}) ??
              'Watch an ad for $hours hours of Pro',
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _OwnedNotice extends StatelessWidget {
  const _OwnedNotice({required this.loc});

  final AppLocalizations? loc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc?.translate('pro_owned_detail') ??
                    'Everything is unlocked. Thank you for supporting the app.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice({required this.loc});

  final AppLocalizations? loc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          loc?.translate('pro_unavailable_platform') ??
              'Pro is not sold on this platform yet.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
