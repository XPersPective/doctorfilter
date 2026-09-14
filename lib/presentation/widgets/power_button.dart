import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';

class PowerButton extends StatelessWidget {
  const PowerButton({
    super.key,
    required this.isActive,
    required this.onTap,
    this.isLoading = false,
  });

  final bool isActive;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final activeGlow = isActive
        ? [
            BoxShadow(
              color: AppTheme.amberPrimary.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: AppTheme.amberPrimary.withValues(alpha: 0.20),
              blurRadius: 48,
              spreadRadius: 10,
            ),
          ]
        : <BoxShadow>[];

    return Semantics(
      button: true,
      label: isActive ? 'Turn off screen filter' : 'Turn on screen filter',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppTheme.amberPrimary : AppTheme.deepNightCard,
              border: Border.all(
                color: isActive
                    ? Colors.white
                    : AppTheme.deepNightBorder.withValues(alpha: 0.8),
                width: 2.5,
              ),
              boxShadow: activeGlow,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: isActive ? Colors.black : AppTheme.amberPrimary,
                      ),
                    )
                  : Icon(
                      Icons.power_settings_new_rounded,
                      size: 42,
                      color: isActive ? Colors.black : Colors.grey.shade400,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
