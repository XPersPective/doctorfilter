import 'package:flutter/material.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

/// The DoctorFilter logo: mark on the left, the two-colour slanted wordmark on
/// the right, the tagline underneath, and a small PRO superscript for owners.
///
/// The wordmark follows the original 1.x logo — lowercase "doctor" in yellow,
/// "Filter" in blue, Audiowide leaning forward. On a light background those
/// exact colours wash out, so the light theme uses deeper shades of the same
/// two hues rather than a different pair.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, required this.isPro});

  final bool isPro;

  static const _doctorOnDark = Color(0xFFFFD200);
  static const _filterOnDark = Color(0xFF00BCFF);
  static const _doctorOnLight = Color(0xFFE08600);
  static const _filterOnLight = Color(0xFF0077E0);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
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
            TextSpan(children: [
              TextSpan(
                text: 'doctor',
                style: wordStyle.copyWith(
                  color: dark ? _doctorOnDark : _doctorOnLight,
                ),
              ),
              TextSpan(
                text: 'Filter',
                style: wordStyle.copyWith(
                  color: dark ? _filterOnDark : _filterOnLight,
                ),
              ),
            ]),
            maxLines: 1,
          ),
        ),
        if (isPro) ...[
          const SizedBox(width: 3),
          // Superscript, the way a trademark sits: a badge the owner notices
          // and nobody else has to read.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: context.colours.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'PRO',
              style: context.texts.labelSmall?.copyWith(
                color: context.colours.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 8,
                letterSpacing: 0.5,
                height: 1.1,
              ),
            ),
          ),
        ],
      ],
    );

    return Semantics(
      label: isPro ? 'DoctorFilter Pro' : 'DoctorFilter',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/brand_mark.png', width: 40, height: 40),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: wordmark),
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
            ),
          ),
        ],
      ),
    );
  }
}
