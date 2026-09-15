import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';

/// Icons for the built-in presets.
///
/// Material's rounded set, which has a matching SF Symbol on iOS, so the app
/// does not need two icon vocabularies when it ships there.
const Map<String, IconData> kPresetIcons = {
  'daylight': Icons.wb_sunny_rounded,
  'office': Icons.light_mode_rounded,
  'evening': Icons.wb_twilight_rounded,
  'incandescent': Icons.lightbulb_rounded,
  'reading': Icons.menu_book_rounded,
  'night': Icons.nightlight_round,
  'candle': Icons.local_fire_department_rounded,
  'custom': Icons.tune_rounded,
};

/// The presets, as a grid.
///
/// A horizontal carousel hid most of the presets off-screen and made the user
/// swipe to find one they use every night. A grid shows all of them at once,
/// which is both faster and less screen area for the same content.
///
/// Reorderable in place: press and hold moves a preset, so the ones someone
/// actually uses can sit where their thumb lands.
class PresetGrid extends StatelessWidget {
  const PresetGrid({
    super.key,
    required this.presets,
    required this.activePresetId,
    required this.onSelected,
    this.onReorder,
    this.lockedFrom,
    this.onLockedTap,
  });

  final List<FilterPreset> presets;
  final int activePresetId;
  final ValueChanged<int> onSelected;

  /// Called with the new order after a drag. Null disables reordering.
  final ValueChanged<List<int>>? onReorder;

  /// Index from which presets require Pro, or null when everything is unlocked.
  final int? lockedFrom;
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    if (presets.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Four across on a phone, more on a tablet. Derived from width rather
        // than hardcoded so the grid does not become a row of stamps on a large
        // screen.
        final columns = (constraints.maxWidth / 92).floor().clamp(3, 8);

        return ReorderableGridView(
          columns: columns,
          onReorder: onReorder == null
              ? null
              : (oldIndex, newIndex) {
                  final order = presets.map((preset) => preset.id).toList();
                  final moved = order.removeAt(oldIndex);
                  order.insert(newIndex, moved);
                  onReorder!(order);
                },
          children: [
            for (var index = 0; index < presets.length; index++)
              _PresetTile(
                key: ValueKey(presets[index].id),
                preset: presets[index],
                isActive: presets[index].id == activePresetId,
                isLocked: lockedFrom != null && index >= lockedFrom!,
                onTap: () {
                  if (lockedFrom != null && index >= lockedFrom!) {
                    onLockedTap?.call();
                    return;
                  }
                  HapticFeedback.selectionClick();
                  onSelected(presets[index].id);
                },
              ),
          ],
        );
      },
    );
  }
}

/// Wraps [ReorderableListView]'s behaviour in a wrapping grid.
///
/// Flutter has no reorderable grid, and pulling in a package for one widget is
/// not worth the dependency: a [Wrap] of draggables covers it, and long-press to
/// drag is the gesture people already expect from home-screen icons.
class ReorderableGridView extends StatelessWidget {
  const ReorderableGridView({
    super.key,
    required this.columns,
    required this.children,
    this.onReorder,
  });

  final int columns;
  final List<Widget> children;
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < children.length; index++)
              SizedBox(
                width: tileWidth,
                child: onReorder == null
                    ? children[index]
                    : _Draggable(
                        index: index,
                        onReorder: onReorder!,
                        child: children[index],
                      ),
              ),
          ],
        );
      },
    );
  }
}

class _Draggable extends StatelessWidget {
  const _Draggable({
    required this.index,
    required this.onReorder,
    required this.child,
  });

  final int index;
  final void Function(int oldIndex, int newIndex) onReorder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onReorder(details.data, index),
      builder: (context, candidate, rejected) {
        final isTarget = candidate.isNotEmpty;
        return LongPressDraggable<int>(
          data: index,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(opacity: 0.85, child: SizedBox(width: 84, child: child)),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: child),
          child: AnimatedScale(
            scale: isTarget ? 1.06 : 1,
            duration: const Duration(milliseconds: 150),
            child: child,
          ),
        );
      },
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    super.key,
    required this.preset,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
  });

  final FilterPreset preset;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final tintRgb = preset.tintRgb;
    final tint = Color.fromARGB(255, tintRgb.r, tintRgb.g, tintRgb.b);

    final name = preset.isCustom
        ? preset.nameKey
        : (loc?.translate(preset.nameKey) ?? preset.nameKey);

    return Semantics(
      button: true,
      selected: isActive,
      label: '$name, ${preset.kelvin} kelvin',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? context.colours.primary.withValues(alpha: 0.14)
                : context.colours.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? context.colours.primary : context.colours.outlineVariant,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tint.withValues(alpha: isLocked ? 0.35 : 1),
                      border: Border.all(
                        color: context.colours.outlineVariant,
                      ),
                    ),
                    child: Icon(
                      kPresetIcons[preset.iconIdentifier] ?? Icons.tune_rounded,
                      size: 18,
                      // Dark ink on the swatch: every tint on the Planckian
                      // locus is light, so black is always the readable choice.
                      color: Colors.black.withValues(alpha: isLocked ? 0.35 : 0.72),
                    ),
                  ),
                  if (isLocked)
                    Positioned(
                      right: -4,
                      bottom: -2,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: context.colours.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.texts.labelMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? context.colours.primary : context.colours.onSurface,
                ),
              ),
              Text(
                '${preset.kelvin} K',
                maxLines: 1,
                // Readable, not decorative: at 9px this was the number the user
                // could not read, in an app whose whole claim is the number.
                style: context.texts.labelSmall?.copyWith(
                  fontFamily: 'Orbitron',
                  color: context.colours.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
