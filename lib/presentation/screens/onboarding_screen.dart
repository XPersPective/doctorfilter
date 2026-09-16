import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/presentation/providers/filter_provider.dart';

/// First-run introduction.
///
/// Three screens, skippable from the first one. The middle screen exists for a
/// specific reason: "draw over other apps" is an alarming permission to be asked
/// for cold, and a user who understands *why* before the system dialog appears
/// is far more likely to grant it — and far less likely to conclude the app is
/// reading their screen.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final pages = _pages(loc);
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: widget.onFinished,
                child: Text(loc?.translate('onboarding_skip') ?? 'Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => _Page(page: pages[index]),
              ),
            ),
            _Dots(count: pages.length, current: _page),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () {
                  if (isLast) {
                    widget.onFinished();
                    return;
                  }
                  // Asking for the permission on the page that explains it, so
                  // the system dialog lands while the reason is still on screen.
                  if (pages[_page].requestsPermission) {
                    ref.read(filterProvider.notifier).requestPermission();
                  }
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                  );
                },
                child: Text(
                  isLast
                      ? (loc?.translate('onboarding_start') ?? 'Start')
                      : pages[_page].requestsPermission
                          ? (loc?.translate('permission_grant_btn') ?? 'Grant permission')
                          : (loc?.translate('onboarding_next') ?? 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_PageData> _pages(AppLocalizations? loc) => [
        _PageData(
          icon: Icons.visibility_rounded,
          // The same mark the user just tapped on the home screen.
          image: 'assets/images/brand_mark.png',
          title: loc?.translate('onboarding_welcome_title') ?? 'Welcome',
          body: loc?.translate('onboarding_welcome_body') ?? '',
          // The brand line belongs on the first screen a person actually reads,
          // not on a splash. Android's system splash cannot draw text, and
          // holding the app back behind a Flutter one purely to make room for a
          // strapline would be adding a delay to show marketing copy.
          tagline: loc?.translate('app_tagline'),
        ),
        _PageData(
          icon: Icons.layers_rounded,
          title: loc?.translate('onboarding_permission_title') ?? 'One permission',
          body: loc?.translate('onboarding_permission_body') ?? '',
          requestsPermission: true,
        ),
        _PageData(
          icon: Icons.tune_rounded,
          title: loc?.translate('onboarding_ready_title') ?? 'You are set',
          body: loc?.translate('onboarding_ready_body') ?? '',
        ),
      ];
}

class _PageData {
  const _PageData({
    required this.icon,
    this.image,
    required this.title,
    required this.body,
    this.requestsPermission = false,
    this.tagline,
  });

  final IconData icon;
  final String? image;
  final String title;
  final String body;
  final bool requestsPermission;

  /// A short line under the mark, on the first slide only.
  final String? tagline;
}

class _Page extends StatelessWidget {
  const _Page({required this.page});

  final _PageData page;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          if (page.image != null)
            Image.asset(page.image!, width: 112, height: 112)
          else
            Icon(page.icon, size: 84, color: context.colours.primary),
          if (page.tagline != null) ...[
            const SizedBox(height: 16),
            Text(
              page.tagline!,
              textAlign: TextAlign.center,
              style: context.texts.labelMedium?.copyWith(
                color: context.colours.primary,
                letterSpacing: 0.4,
              ),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: context.texts.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium?.copyWith(
              color: context.colours.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == current
                  ? context.colours.primary
                  : context.colours.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
