import 'package:flutter/material.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

/// What the app knows, and how it knows it.
///
/// Rewritten from scratch. The 1.x text claimed screens damage the retina, cause
/// macular degeneration and make people overeat — none of which the evidence
/// supports, and all of which would be a misleading health claim in a store
/// listing. What replaces it is narrower, sourced, and more useful: the parts
/// that are well established get stated plainly, and the part people most often
/// get wrong — that blue light causes eye strain — is corrected rather than sold.
class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('education_title') ?? 'Eye health'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const _SpectrumFigure(),
          const SizedBox(height: 20),
          _Article(
            icon: Icons.waves_rounded,
            title: loc?.translate('edu_spectrum_title') ??
                'Visible light and your body clock',
            body: loc?.translate('edu_spectrum_body') ?? '',
          ),
          _Article(
            icon: Icons.thermostat_rounded,
            title: loc?.translate('edu_kelvin_title') ??
                'What colour temperature means',
            body: loc?.translate('edu_kelvin_body') ?? '',
            figure: const _KelvinScale(),
          ),
          _Article(
            icon: Icons.nightlight_round,
            title: loc?.translate('edu_melanopic_title') ??
                'The number that actually matters',
            body: loc?.translate('edu_melanopic_body') ?? '',
          ),
          _Article(
            icon: Icons.brightness_low_rounded,
            title: loc?.translate('edu_dimming_title') ?? 'Dimming beats warming',
            body: loc?.translate('edu_dimming_body') ?? '',
          ),
          _Article(
            icon: Icons.visibility_outlined,
            title: loc?.translate('edu_strain_title') ?? 'About tired eyes',
            body: loc?.translate('edu_strain_body') ?? '',
          ),
          const SizedBox(height: 8),
          _Sources(loc: loc),
        ],
      ),
    );
  }
}

/// The visible spectrum, with the melanopic peak marked.
///
/// Drawn rather than shipped as an image: it stays sharp at any size, costs no
/// download, and — more to the point — it is generated from the same wavelength
/// numbers the text cites, so the picture cannot drift away from the words.
class _SpectrumFigure extends StatelessWidget {
  const _SpectrumFigure();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: CustomPaint(
              painter: _SpectrumPainter(
                markerColour: context.colours.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('380 nm', style: _tinyLabel(context)),
            Text('480 nm · melanopsin', style: _tinyLabel(context)),
            Text('780 nm', style: _tinyLabel(context)),
          ],
        ),
      ],
    );
  }

  TextStyle? _tinyLabel(BuildContext context) => context.texts.labelSmall
      ?.copyWith(color: context.colours.onSurfaceVariant);
}

class _SpectrumPainter extends CustomPainter {
  const _SpectrumPainter({required this.markerColour});

  final Color markerColour;

  /// Approximate sRGB renderings of monochromatic light, 380–780 nm.
  static const _stops = <Color>[
    Color(0xFF2A004F), // 380
    Color(0xFF4B0082), // 420
    Color(0xFF0000FF), // 460
    Color(0xFF00BFFF), // 490
    Color(0xFF00FF00), // 530
    Color(0xFFFFFF00), // 580
    Color(0xFFFF7F00), // 620
    Color(0xFFFF0000), // 680
    Color(0xFF6B0000), // 780
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(colors: _stops).createShader(rect),
    );

    // 480 nm, where melanopsin peaks — the reason the whole app exists.
    const peak = (480 - 380) / (780 - 380);
    final x = size.width * peak;
    canvas.drawRect(
      Rect.fromLTWH(x - 1.5, 0, 3, size.height),
      Paint()..color = markerColour,
    );
  }

  @override
  bool shouldRepaint(_SpectrumPainter oldDelegate) =>
      oldDelegate.markerColour != markerColour;
}

/// Real light sources along the Kelvin scale, coloured by the engine itself.
class _KelvinScale extends StatelessWidget {
  const _KelvinScale();

  static const _examples = <({int kelvin, IconData icon})>[
    (kelvin: 1850, icon: Icons.local_fire_department_rounded),
    (kelvin: 2700, icon: Icons.lightbulb_rounded),
    (kelvin: 4300, icon: Icons.light_mode_rounded),
    (kelvin: 5500, icon: Icons.wb_sunny_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final example in _examples)
          Builder(
            builder: (context) {
              final rgb = KelvinEngine.kelvinToRgb(example.kelvin);
              return Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromARGB(255, rgb.r, rgb.g, rgb.b),
                      border: Border.all(color: context.colours.outlineVariant),
                    ),
                    child: Icon(
                      example.icon,
                      size: 19,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ltrIsolate('${example.kelvin} K'),
                    style: context.texts.labelSmall?.copyWith(
                      fontFamily: 'Orbitron',
                      color: context.colours.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _Article extends StatelessWidget {
  const _Article({
    required this.icon,
    required this.title,
    required this.body,
    this.figure,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? figure;

  @override
  Widget build(BuildContext context) {
    if (body.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: context.colours.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: context.texts.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colours.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (figure != null) ...[
              const SizedBox(height: 16),
              figure!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Every claim above, with its source.
///
/// The point of an open-source app making scientific claims is that both the
/// code and the citations can be checked.
class _Sources extends StatelessWidget {
  const _Sources({required this.loc});

  final AppLocalizations? loc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        loc?.translate('edu_sources_note') ?? '',
        textAlign: TextAlign.center,
        style: context.texts.labelSmall?.copyWith(
          color: context.colours.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}
