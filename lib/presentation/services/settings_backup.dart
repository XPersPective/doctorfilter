import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:doctorfilter/data/datasources/local/database_helper.dart';
import 'package:doctorfilter/data/datasources/local/preferences_datasource.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';

/// Exporting and restoring settings as a plain JSON file.
///
/// The app has no account and no cloud, which is the point — but it also means
/// a new phone starts from nothing unless the user can carry their setup across
/// themselves. A file they can see, read and keep is the honest version of
/// "backup" for an app that promises to send nothing anywhere.
///
/// Entitlement is deliberately *not* in the backup. Pro comes from the store,
/// and a JSON file that could grant it would be an invitation to edit it.
abstract final class SettingsBackup {
  /// Bumped if the shape changes, so a future version can refuse or migrate a
  /// file rather than silently misreading it.
  static const int formatVersion = 1;

  static const String _fileName = 'doctorfilter-settings.json';

  static Map<String, Object?> _encode({
    required FilterConfig config,
    required List<FilterPreset> presets,
  }) {
    return {
      'format': formatVersion,
      'exported': DateTime.now().toIso8601String(),
      'filter': {
        'kelvin': config.kelvin,
        'densityPercent': config.densityPercent,
        'extraDimPercent': config.extraDimPercent,
        'activePresetId': config.activePresetId,
        'notification': config.isNotificationEnabled,
      },
      'presets': [
        // Built-in presets are not exported: they exist in every install, and
        // re-importing them would overwrite whatever the shipped values have
        // become in a later version.
        for (final preset in presets.where((preset) => preset.isCustom))
          {
            'name': preset.nameKey,
            'kelvin': preset.kelvin,
            'densityPercent': preset.densityPercent,
            'extraDimPercent': preset.extraDimPercent,
            'icon': preset.iconIdentifier,
          },
      ],
    };
  }

  /// Writes the backup and hands it to the system share sheet.
  ///
  /// Returns false if it could not be written; the caller tells the user rather
  /// than leaving them believing they have a backup.
  static Future<bool> export({
    required FilterConfig config,
    required List<FilterPreset> presets,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$_fileName');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ')
            .convert(_encode(config: config, presets: presets)),
      );

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], fileNameOverrides: [_fileName]),
      );
      return true;
    } catch (error) {
      if (kDebugMode) debugPrint('[Backup] Export failed: $error');
      return false;
    }
  }

  /// Reads a backup file and applies it.
  ///
  /// Every value goes through [FilterConfig] and [FilterPreset], so a
  /// hand-edited file cannot push the screen past the safety caps: a JSON that
  /// says 100% density becomes 80%, not a black screen.
  static Future<bool> import({
    required String json,
    required PreferencesDataSource preferences,
    required DatabaseHelper database,
  }) async {
    try {
      final data = jsonDecode(json);
      if (data is! Map<String, dynamic>) return false;
      if (data['format'] != formatVersion) return false;

      final filter = data['filter'];
      if (filter is Map<String, dynamic>) {
        final current = preferences.getFilterConfig();
        await preferences.saveFilterConfig(
          current.copyWith(
            kelvin: filter['kelvin'] as int?,
            densityPercent: filter['densityPercent'] as int?,
            extraDimPercent: filter['extraDimPercent'] as int?,
            activePresetId: filter['activePresetId'] as int?,
            isNotificationEnabled: filter['notification'] as bool?,
          ),
        );
      }

      final presets = data['presets'];
      if (presets is List) {
        var nextId = await database.nextCustomPresetId();
        for (final entry in presets) {
          if (entry is! Map<String, dynamic>) continue;
          await database.insertOrUpdatePreset(
            FilterPreset(
              // A new id rather than the exported one: importing onto a device
              // that already has presets must add to them, not overwrite by
              // coincidence of numbering.
              id: nextId++,
              nameKey: (entry['name'] as String?)?.trim().isNotEmpty == true
                  ? entry['name'] as String
                  : 'Imported',
              kelvin: (entry['kelvin'] as int?) ?? 2700,
              densityPercent: (entry['densityPercent'] as int?) ?? 45,
              extraDimPercent: (entry['extraDimPercent'] as int?) ?? 35,
              iconIdentifier: (entry['icon'] as String?) ?? 'custom',
              isCustom: true,
            ),
          );
        }
      }

      return true;
    } catch (error) {
      if (kDebugMode) debugPrint('[Backup] Import failed: $error');
      return false;
    }
  }
}
