import 'package:flutter/material.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

/// The DoctorFilter logo: mark on the left, the two-colour slanted wordmark on
/// the right, the tagline underneath, and a small PRO superscript for owners.
///
/// The wordmark is coloured with the icon's own two colours — "doctor" in the
/// mark's orange, "Filter" in its blue — so the icon and the name read as one
/// logo. The same two colours in both themes: they are the brand, and both
/// hold enough contrast on the app's light and dark backgrounds.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, required this.isPro, this.showTagline = true});

  /// Draws the PRO mark. True for owners on the home screen, and always on the
  /// Pro page, whose title is the logo itself.
  final bool isPro;

  /// The strapline under the name. Off where the bar is already busy.
  final bool showTagline;

  // Sampled from the icon (tool/brand/generate_icons.py: ORANGE, BLUE).
  static const _orange = Color(0xFFFF9900);
  static const _blue = Color(0xFF0087FF);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const wordStyle = TextStyle(
      fontFamily: 'Audiowide',
      fontSize: 22,
      height: 1.0,
    );

    final wordmark = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slanted as a unit so the two words keep one baseline.
        Transform(
          transform: Matrix4.skewX(-0.22),
          alignment: Alignment.bottomLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'doctor',
                  style: wordStyle.copyWith(color: _orange),
                ),
                TextSpan(
                  text: 'Filter',
                  style: wordStyle.copyWith(color: _blue),
                ),
              ],
            ),
            maxLines: 1,
          ),
        ),
        if (isPro) ...[
          const SizedBox(width: 3),
          // Superscript at the top of the name, the way a trademark sits: small
          // enough that nobody has to read it, in the logo's own two colours.
          const _ProMark(),
        ],
      ],
    );

    return Semantics(
      label: isPro ? 'DoctorFilter Pro' : 'DoctorFilter',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The PNG carries a transparent margin on every side for its shadow,
          // which read as a wide gap before the name. Laying it out 5dp
          // narrower lets that margin fall behind the text instead.
          SizedBox(
            width: 35,
            height: 40,
            child: OverflowBox(
              maxWidth: 40,
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/brand_mark.png',
                width: 40,
                height: 40,
              ),
            ),
          ),
          const SizedBox(width: 1),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: wordmark),
                if (showTagline) ...[
                  const SizedBox(height: 3),
                  Text(
                    loc?.translate('app_tagline') ??
                        'Measured in kelvin. Honest about the numbers.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.labelSmall?.copyWith(
                      color: context.colours.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProMark extends StatelessWidget {
  const _ProMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      // Orange lettering on a faint orange ground with a hairline edge: part of
      // the logo's palette without competing with the name beside it.
      decoration: BoxDecoration(
        color: BrandLockup._orange.withValues(alpha: 0.14),
        border: Border.all(
          color: BrandLockup._orange.withValues(alpha: 0.6),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          fontFamily: 'Audiowide',
          color: BrandLockup._orange,
          fontSize: 7.5,
          height: 1.0,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
