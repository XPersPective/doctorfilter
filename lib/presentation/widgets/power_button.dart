import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

/// The master on/off control.
///
/// Smaller than it was, and paired with its own label instead of a separate
/// caption below — the old 88px circle plus a line of status text took a fifth
/// of the screen to say one bit of information.
class PowerButton extends StatelessWidget {
  const PowerButton({
    super.key,
    required this.isActive,
    required this.onTap,
    required this.label,
    this.isLoading = false,
  });

  final bool isActive;
  final VoidCallback onTap;

  /// Announced to screen readers and shown beside the button.
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final accent = context.colours.primary;

    return Semantics(
      button: true,
      toggled: isActive,
      label: label,
      // The visible label is the same words; without this TalkBack reads them
      // twice. Excluding the children also drops the InkWell's tap action, so
      // it is declared again here.
      excludeSemantics: true,
      onTap: isLoading ? null : onTap,
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onTap();
              },
        borderRadius: BorderRadius.circular(32),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? accent : context.colours.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isActive ? accent : context.colours.outlineVariant,
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: isLoading
                    ? CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: isActive
                            ? context.colours.onPrimary
                            : context.colours.onSurface,
                      )
                    : Icon(
                        Icons.power_settings_new_rounded,
                        size: 24,
                        color: isActive
                            ? context.colours.onPrimary
                            : context.colours.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: context.texts.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? context.colours.onPrimary
                      : context.colours.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
