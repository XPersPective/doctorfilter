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
        title: Text(loc?.translate('education_title') ?? 'Light and your screen'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _SpectrumFigure(),
          const SizedBox(height: 22),
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

/// The logo's two colours, used as light in the figures.
const _brandOrange = Color(0xFFFF9900);
const _brandBlue = Color(0xFF0087FF);

/// The visible spectrum, with the melanopic peak marked and labelled.
///
/// Drawn rather than shipped as an image: it stays sharp at any size, costs no
/// download, and — more to the point — it is generated from the same wavelength
/// numbers the text cites, so the picture cannot drift away from the words.
class _SpectrumFigure extends StatelessWidget {
  const _SpectrumFigure();

  // 480 nm, where melanopsin peaks, as a fraction of 380–780 nm.
  static const _peak = (480 - 380) / (780 - 380);

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    // Wavelength runs left to right in every language.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.surfaceContainerHigh, c.surfaceContainerLow],
          ),
          border: Border.all(color: c.outlineVariant.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: _brandBlue.withValues(alpha: 0.16),
              blurRadius: 40,
              offset: const Offset(-8, 10),
            ),
            BoxShadow(
              color: _brandOrange.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(8, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            const labelWidth = 150.0;
            final x = box.maxWidth * _peak;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The peak label sits above its own line on the spectrum.
                SizedBox(
                  height: 28,
                  child: Stack(
                    children: [
                      Positioned(
                        left: (x - labelWidth / 2)
                            .clamp(0.0, box.maxWidth - labelWidth),
                        width: labelWidth,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _brandBlue.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: _brandBlue.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              '480 nm · melanopsin',
                              style: context.texts.labelSmall?.copyWith(
                                color: c.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const SizedBox(
                    height: 96,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SpectrumPainter(markerColour: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('380 nm', style: _tinyLabel(context)),
                    Text('780 nm', style: _tinyLabel(context)),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  TextStyle? _tinyLabel(BuildContext context) =>
      context.texts.labelSmall?.copyWith(
        fontFamily: 'Orbitron',
        color: context.colours.onSurfaceVariant,
      );
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
    // A soft glow under a sharp line.
    const peak = (480 - 380) / (780 - 380);
    final x = size.width * peak;
    canvas.drawRect(
      Rect.fromLTWH(x - 6, 0, 12, size.height),
      Paint()
        ..color = markerColour.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
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

  static Color _colour(int kelvin) {
    final rgb = KelvinEngine.kelvinToRgb(kelvin);
    return Color.fromARGB(255, rgb.r, rgb.g, rgb.b);
  }

  @override
  Widget build(BuildContext context) {
    // The bar comes from the same engine that colours the filter, candlelight
    // to daylight, so it shows the app's real output.
    final bar = [for (var k = 1700; k <= 6500; k += 400) _colour(k)];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(colors: bar),
              boxShadow: [
                BoxShadow(
                  color: _colour(2200).withValues(alpha: 0.45),
                  blurRadius: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final example in _examples)
                Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _colour(example.kelvin),
                        boxShadow: [
                          BoxShadow(
                            color: _colour(example.kelvin)
                                .withValues(alpha: 0.55),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Icon(
                        example.icon,
                        size: 22,
                        color: Colors.black.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${example.kelvin} K',
                      style: context.texts.labelSmall?.copyWith(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w600,
                        color: context.colours.onSurface,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
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
    final c = context.colours;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thin brand edge: orange into blue, the logo's two colours.
            Container(
              width: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_brandOrange, _brandBlue],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, size: 20, color: c.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: context.texts.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      style: context.texts.bodyMedium?.copyWith(
                        color: c.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                    if (figure != null) ...[
                      const SizedBox(height: 18),
                      figure!,
                    ],
                  ],
                ),
              ),
            ),
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
    final note = loc?.translate('edu_sources_note') ?? '';
    if (note.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colours.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 18, color: context.colours.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note,
              style: context.texts.labelSmall?.copyWith(
                color: context.colours.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
