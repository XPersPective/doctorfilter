import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';
import 'package:doctorfilter/domain/entities/preset_code.dart';
import 'package:doctorfilter/presentation/services/app_links.dart';
import 'package:doctorfilter/presentation/providers/filter_provider.dart';
import 'package:doctorfilter/presentation/providers/preset_provider.dart';
import 'package:doctorfilter/presentation/widgets/axis_slider.dart';
import 'package:doctorfilter/presentation/widgets/preset_grid.dart';
import 'package:doctorfilter/presentation/widgets/spectrum_slider.dart';

/// Managing presets: create, edit, reset, delete.
class PresetsScreen extends ConsumerWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final presets = ref.watch(presetProvider).presets;
    final activeId = ref.watch(filterConfigProvider).activePresetId;
    final notifier = ref.read(presetProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('nav_presets') ?? 'Presets'),
        actions: [
          IconButton(
            tooltip: loc?.translate('preset_import') ?? 'Enter a preset code',
            icon: const Icon(Icons.keyboard_alt_outlined),
            onPressed: () => _importCode(context, notifier),
          ),
          IconButton(
            tooltip: loc?.translate('preset_reset_all') ?? 'Reset all presets',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () => _confirmResetAll(context, notifier),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          for (final preset in presets)
            _PresetRow(
              preset: preset,
              isActive: preset.id == activeId,
              onApply: () => notifier.select(preset.id),
              onEdit: () => _editPreset(context, preset),
              onShare: () => _shareCode(context, preset),
              onReset:
                  preset.isCustom ? null : () => notifier.resetToDefault(preset.id),
              onDelete: preset.isCustom
                  ? () => _confirmDelete(context, notifier, preset)
                  : null,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editPreset(context, null),
        icon: const Icon(Icons.add_rounded),
        label: Text(loc?.translate('preset_new') ?? 'New preset'),
      ),
    );
  }

  /// Hands the five-character code to the share sheet.
  ///
  /// No server, no account, no link that stops working: the preset *is* the
  /// code, and it fits in any message the user was already sending.
  static Future<void> _shareCode(BuildContext context, FilterPreset preset) {
    final loc = AppLocalizations.of(context);
    final code = PresetCode.ofPreset(preset);
    final template = loc?.translate('preset_share_text');

    return AppLinks.share(
      template == null
          ? 'DoctorFilter preset: $code'
          : template.replaceAll('{code}', code),
    );
  }

  Future<void> _importCode(BuildContext context, PresetNotifier notifier) async {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc?.translate('preset_import') ?? 'Enter a preset code'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 5,
          decoration: InputDecoration(
            hintText: loc?.translate('preset_import_hint') ?? 'Five characters',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc?.translate('action_cancel') ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(loc?.translate('action_add') ?? 'Add'),
          ),
        ],
      ),
    );

    if (code == null) return;
    final decoded = PresetCode.decode(code);

    if (!context.mounted) return;
    if (decoded == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              loc?.translate('preset_import_invalid') ??
                  'That code is not valid.',
            ),
          ),
        );
      return;
    }

    // Named after its own colour temperature: a name in the sender's language
    // would be noise to whoever received it, so the code carries no name.
    await notifier.saveCustom(
      name: '${decoded.kelvin} K',
      kelvin: decoded.kelvin,
      densityPercent: decoded.densityPercent,
      extraDimPercent: decoded.extraDimPercent,
    );
  }

  Future<void> _confirmResetAll(
    BuildContext context,
    PresetNotifier notifier,
  ) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc?.translate('preset_reset_all') ?? 'Reset all presets'),
        content: Text(
          loc?.translate('preset_reset_all_confirm') ??
              'This restores the built-in presets. Your own presets are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc?.translate('action_cancel') ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc?.translate('action_reset') ?? 'Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) await notifier.resetAllToDefaults();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PresetNotifier notifier,
    FilterPreset preset,
  ) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(
          loc?.translate('preset_delete_confirm') ?? 'Delete this preset?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc?.translate('action_cancel') ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc?.translate('action_delete') ?? 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await notifier.delete(preset.id);
  }

  Future<void> _editPreset(BuildContext context, FilterPreset? existing) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _PresetEditor(existing: existing),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.preset,
    required this.isActive,
    required this.onApply,
    required this.onEdit,
    required this.onShare,
    this.onReset,
    this.onDelete,
  });

  final FilterPreset preset;
  final bool isActive;
  final VoidCallback onApply;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback? onReset;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final rgb = preset.tintRgb;
    final tint = Color.fromARGB(255, rgb.r, rgb.g, rgb.b);
    final name = preset.isCustom
        ? preset.nameKey
        : (loc?.translate(preset.nameKey) ?? preset.nameKey);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? context.colours.primary : context.colours.outlineVariant,
          width: isActive ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: onApply,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tint,
            border: Border.all(color: context.colours.outlineVariant),
          ),
          child: Icon(
            kPresetIcons[preset.iconIdentifier] ?? Icons.tune_rounded,
            size: 21,
            // Every tint on the Planckian locus is light, so dark ink is always
            // the readable choice on the swatch.
            color: Colors.black.withValues(alpha: 0.7),
          ),
        ),
        title: Text(
          name,
          style: context.texts.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isActive ? context.colours.primary : null,
          ),
        ),
        subtitle: Text(
          '${preset.kelvin} K · ${preset.densityPercent}% · ${preset.extraDimPercent}%',
          style: context.texts.bodySmall?.copyWith(
            fontFamily: 'Orbitron',
            color: context.colours.onSurfaceVariant,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (action) => switch (action) {
            'edit' => onEdit(),
            'share' => onShare(),
            'reset' => onReset?.call(),
            'delete' => onDelete?.call(),
            _ => null,
          },
          itemBuilder: (menuContext) => [
            PopupMenuItem(
              value: 'edit',
              child: Text(loc?.translate('action_manage') ?? 'Edit'),
            ),
            PopupMenuItem(
              value: 'share',
              child: Text(loc?.translate('preset_share') ?? 'Share as a code'),
            ),
            if (onReset != null)
              PopupMenuItem(
                value: 'reset',
                child:
                    Text(loc?.translate('preset_reset_one') ?? 'Reset this preset'),
              ),
            if (onDelete != null)
              PopupMenuItem(
                value: 'delete',
                child: Text(loc?.translate('action_delete') ?? 'Delete'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Create or edit a preset.
///
/// All three axes. The previous editor offered colour and density only, so a
/// preset could not express the setting that does the most work.
class _PresetEditor extends ConsumerStatefulWidget {
  const _PresetEditor({this.existing});

  final FilterPreset? existing;

  @override
  ConsumerState<_PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<_PresetEditor> {
  late final TextEditingController _name;
  late int _kelvin;
  late int _density;
  late int _extraDim;
  late String _icon;
  bool _nameMissing = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(
      text: existing?.isCustom == true ? existing!.nameKey : '',
    );
    _kelvin = existing?.kelvin ?? 2700;
    _density = existing?.densityPercent ?? 45;
    _extraDim = existing?.extraDimPercent ?? 35;
    _icon = existing?.iconIdentifier ?? 'custom';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final rgb = KelvinEngine.kelvinToRgb(_kelvin);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? (loc?.translate('preset_new') ?? 'New preset')
                        : (loc?.translate('action_manage') ?? 'Edit'),
                    style: context.texts.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromARGB(255, rgb.r, rgb.g, rgb.b),
                    border: Border.all(color: context.colours.outlineVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: loc?.translate('preset_name') ?? 'Name',
                hintText: loc?.translate('preset_name_hint'),
                errorText: _nameMissing
                    ? (loc?.translate('preset_name') ?? 'Name')
                    : null,
              ),
              onChanged: (_) {
                if (_nameMissing) setState(() => _nameMissing = false);
              },
            ),
            const SizedBox(height: 16),
            _IconPicker(
              selected: _icon,
              onSelected: (icon) => setState(() => _icon = icon),
            ),
            const SizedBox(height: 16),
            SpectrumSlider(
              kelvin: _kelvin,
              onChanged: (value) => setState(() => _kelvin = value),
            ),
            AxisSlider(
              label: loc?.translate('density_label') ?? 'Filter density',
              value: _density,
              max: FilterConfig.maxDensityPercent,
              icon: Icons.opacity_rounded,
              onChanged: (value) => setState(() => _density = value),
            ),
            AxisSlider(
              label: loc?.translate('extra_dim_label') ?? 'Extra dim',
              hint: loc?.translate('extra_dim_hint'),
              value: _extraDim,
              max: FilterConfig.maxExtraDimPercent,
              icon: Icons.brightness_medium_rounded,
              onChanged: (value) => setState(() => _extraDim = value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _save,
              child: Text(loc?.translate('action_save') ?? 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      // An unnamed preset is one the user cannot find again.
      setState(() => _nameMissing = true);
      return;
    }

    await ref.read(presetProvider.notifier).saveCustom(
          name: name,
          kelvin: _kelvin,
          densityPercent: _density,
          extraDimPercent: _extraDim,
          iconIdentifier: _icon,
          replacingId:
              widget.existing?.isCustom == true ? widget.existing!.id : null,
        );

    if (mounted) Navigator.pop(context);
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in kPresetIcons.entries)
          IconButton(
            isSelected: entry.key == selected,
            onPressed: () => onSelected(entry.key),
            icon: Icon(entry.value),
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: entry.key == selected
                  ? context.colours.primary.withValues(alpha: 0.16)
                  : null,
              foregroundColor: entry.key == selected
                  ? context.colours.primary
                  : context.colours.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
