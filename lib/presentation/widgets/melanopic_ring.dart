import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/domain/entities/melanopic_target.dart';

/// How far the current settings are round to the evening lighting guidance.
///
/// A ring rather than a bare percentage because the number alone answers the
/// wrong question. "43% less circadian light" tells the user nothing about
/// whether that is enough; an arc with an end to it does.
///
/// The arc is *relative reduction*, never an absolute lx claim — see
/// [MelanopicTarget] for why the app refuses to pretend it can measure that.
class MelanopicRing extends StatelessWidget {
  const MelanopicRing({
    super.key,
    required this.melanopicReduction,
    required this.bandColour,
    required this.bandLabel,
  });

  final double melanopicReduction;
  final Color bandColour;
  final String bandLabel;

  static const double _size = 78;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final percent = (melanopicReduction * 100).round();
    final reached = MelanopicTarget.meetsEvening(melanopicReduction);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                bandLabel,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelLarge?.copyWith(color: bandColour),
              ),
              Text(
                reached
                    ? loc?.translate('melanopic_target_reached') ??
                          'At the evening guidance'
                    : loc?.translate('melanopic_target_progress') ??
                          'Towards the evening guidance',
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodySmall?.copyWith(
                  color: context.colours.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          label: loc?.translate(
            'melanopic_reduction',
            args: {'percent': '$percent'},
          ),
          button: true,
          excludeSemantics: true,
          onTap: () => _explain(context),
          child: InkWell(
            borderRadius: BorderRadius.circular(_size),
            onTap: () => _explain(context),
            child: SizedBox(
              width: _size,
              height: _size,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: MelanopicTarget.progress(melanopicReduction),
                  colour: bandColour,
                  track: context.colours.outlineVariant,
                ),
                child: Center(
                  child: Text(
                    '$percent%',
                    style: context.texts.titleMedium?.copyWith(
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold,
                      color: bandColour,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The assumption behind the ring, spelled out where the user can find it.
  ///
  /// A figure the app cannot justify on demand is a figure it should not show.
  void _explain(BuildContext context) {
    final loc = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          loc?.translate('melanopic_target_title') ?? 'The evening guidance',
        ),
        content: Text(
          loc?.translate('melanopic_target_explainer') ??
              'Expert consensus puts evening light at 10 lx melanopic EDI or '
                  'less in the three hours before bed. No app can measure that '
                  'figure: it depends on your panel, your brightness and how far '
                  'away you hold the screen. The ring shows how much circadian '
                  'light your settings remove relative to an unfiltered screen, '
                  'against a 70% reduction taken as a reasonable stand-in for '
                  'the target. It is a direction, not a measurement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc?.translate('action_ok') ?? 'OK'),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.colour,
    required this.track,
  });

  final double progress;
  final Color colour;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = (size.shortestSide - stroke) / 2;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;

    canvas.drawCircle(centre, radius, base);

    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      // From the top, clockwise, because that is how every progress ring the
      // user has ever seen behaves.
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      base..color = colour,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.colour != colour || old.track != track;
}
