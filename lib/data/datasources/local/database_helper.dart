import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'doctorfilter_v2.db';

  /// v1: hand-entered RGB + alpha + unused brightness.
  /// v2: three-axis model (kelvin / density / extra dim), colour derived.
  static const int _dbVersion = 2;

  static const String tablePresets = 'presets';

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePresets (
        id INTEGER PRIMARY KEY,
        name_key TEXT NOT NULL,
        kelvin INTEGER NOT NULL,
        density_percent INTEGER NOT NULL,
        extra_dim_percent INTEGER NOT NULL,
        icon_identifier TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        is_pro_only INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    final batch = db.batch();
    for (final preset in defaultPresets) {
      batch.insert(tablePresets, _presetToMap(preset));
    }
    await batch.commit(noResult: true);
  }

  /// Migrates presets from the v1 RGB schema.
  ///
  /// Built-in presets are simply replaced — their v1 values were internally
  /// inconsistent (a preset labelled 3500 K rendered a 5405 K colour), so
  /// carrying them forward would carry the defect forward. Custom presets are
  /// the user's own work and are converted rather than discarded:
  ///
  /// * `alpha` (0–255) was the tint strength → density percent.
  /// * `brightness` was stored but never applied by the overlay service. It was
  ///   nonetheless the only place a user's dimming intent was recorded, so it is
  ///   read as its inverse: a low stored brightness means the user wanted a
  ///   darker screen.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion >= 2) return;

    final legacy = await db.query(tablePresets, where: 'is_custom = 1');

    await db.execute('DROP TABLE IF EXISTS $tablePresets');
    await _onCreate(db, newVersion);

    if (legacy.isEmpty) return;

    final batch = db.batch();
    for (final row in legacy) {
      final alpha = (row['alpha'] as int?) ?? 64;
      final brightness = (row['brightness'] as int?) ?? 255;
      batch.insert(
        tablePresets,
        _presetToMap(
          FilterPreset(
            id: row['id'] as int,
            nameKey: (row['name_key'] as String?) ?? 'custom',
            kelvin: (row['kelvin'] as int?) ?? 2700,
            densityPercent: (alpha / 255 * 100).round(),
            extraDimPercent: ((255 - brightness) / 255 * 100).round(),
            iconIdentifier: (row['icon_identifier'] as String?) ?? 'custom',
            isCustom: true,
            sortOrder: defaultPresets.length,
          ),
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// The built-in presets, ordered as a circadian ladder.
  ///
  /// Reading down the list, colour temperature falls while density and dimming
  /// rise — which is the order a day actually runs in, and makes the list itself
  /// teach the idea. Every temperature names a real light source:
  ///
  /// * 5500 K — overcast daylight
  /// * 4300 K — cool white fluorescent, the light of most offices
  /// * 3400 K — halogen / early evening
  /// * 2700 K — standard incandescent bulb
  /// * 2900 K — warm reading light (dimmer than the bulb, for text contrast)
  /// * 2200 K — deep amber, the evening target of Brown et al. (2022)
  /// * 1850 K — candle flame
  ///
  /// Dimming rises faster than density on purpose: lowering brightness does more
  /// for melatonin than shifting colour does (Nagare et al., 2019).
  static List<FilterPreset> get defaultPresets => [
        FilterPreset(
          id: 0,
          nameKey: 'preset_daylight',
          kelvin: 5500,
          densityPercent: 15,
          extraDimPercent: 0,
          iconIdentifier: 'daylight',
          sortOrder: 0,
        ),
        FilterPreset(
          id: 1,
          nameKey: 'preset_office',
          kelvin: 4300,
          densityPercent: 30,
          extraDimPercent: 10,
          iconIdentifier: 'office',
          sortOrder: 1,
        ),
        FilterPreset(
          id: 2,
          nameKey: 'preset_evening',
          kelvin: 3400,
          densityPercent: 40,
          extraDimPercent: 20,
          iconIdentifier: 'evening',
          sortOrder: 2,
        ),
        FilterPreset(
          id: 3,
          nameKey: 'preset_incandescent',
          kelvin: 2700,
          densityPercent: 50,
          extraDimPercent: 30,
          iconIdentifier: 'incandescent',
          sortOrder: 3,
        ),
        FilterPreset(
          id: 4,
          nameKey: 'preset_reading',
          kelvin: 2900,
          densityPercent: 45,
          extraDimPercent: 40,
          iconIdentifier: 'reading',
          sortOrder: 4,
        ),
        FilterPreset(
          id: 5,
          nameKey: 'preset_night',
          kelvin: 2200,
          densityPercent: 60,
          extraDimPercent: 50,
          iconIdentifier: 'night',
          sortOrder: 5,
        ),
        FilterPreset(
          id: 6,
          nameKey: 'preset_candle',
          kelvin: 1850,
          densityPercent: 70,
          extraDimPercent: 60,
          iconIdentifier: 'candle',
          sortOrder: 6,
        ),
      ];

  static Map<String, dynamic> _presetToMap(FilterPreset preset) {
    return {
      'id': preset.id,
      'name_key': preset.nameKey,
      'kelvin': preset.kelvin,
      'density_percent': preset.densityPercent,
      'extra_dim_percent': preset.extraDimPercent,
      'icon_identifier': preset.iconIdentifier,
      'is_custom': preset.isCustom ? 1 : 0,
      'is_pro_only': preset.isProOnly ? 1 : 0,
      'sort_order': preset.sortOrder,
    };
  }

  static FilterPreset presetFromMap(Map<String, dynamic> map) {
    return FilterPreset(
      id: map['id'] as int,
      nameKey: map['name_key'] as String,
      kelvin: map['kelvin'] as int,
      densityPercent: map['density_percent'] as int,
      extraDimPercent: map['extra_dim_percent'] as int,
      iconIdentifier: (map['icon_identifier'] as String?) ?? '',
      isCustom: (map['is_custom'] as int? ?? 0) == 1,
      isProOnly: (map['is_pro_only'] as int? ?? 0) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  Future<List<FilterPreset>> getAllPresets() async {
    final db = await database;
    final maps = await db.query(tablePresets, orderBy: 'sort_order ASC, id ASC');
    return maps.map(presetFromMap).toList();
  }

  Future<FilterPreset?> getPresetById(int id) async {
    final db = await database;
    final maps = await db.query(
      tablePresets,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return presetFromMap(maps.first);
  }

  Future<void> insertOrUpdatePreset(FilterPreset preset) async {
    final db = await database;
    await db.insert(
      tablePresets,
      _presetToMap(preset),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePreset(int id) async {
    final db = await database;
    await db.delete(
      tablePresets,
      where: 'id = ? AND is_custom = 1',
      whereArgs: [id],
    );
  }

  /// Persists a new home-screen ordering.
  Future<void> updateSortOrder(List<int> presetIdsInOrder) async {
    final db = await database;
    final batch = db.batch();
    for (var i = 0; i < presetIdsInOrder.length; i++) {
      batch.update(
        tablePresets,
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [presetIdsInOrder[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Restores a single built-in preset to its shipped values.
  ///
  /// Returns false for custom presets — they have no factory state to return to.
  Future<bool> resetPresetToDefault(int id) async {
    final original = defaultPresets.where((p) => p.id == id).firstOrNull;
    if (original == null) return false;
    await insertOrUpdatePreset(original);
    return true;
  }

  Future<void> resetToDefaults() async {
    final db = await database;
    final batch = db.batch();
    batch.delete(tablePresets);
    for (final preset in defaultPresets) {
      batch.insert(tablePresets, _presetToMap(preset));
    }
    await batch.commit(noResult: true);
  }

  /// Highest id currently stored, so new custom presets never collide.
  Future<int> nextCustomPresetId() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(id) AS max_id FROM $tablePresets');
    final maxId = result.first['max_id'] as int?;
    return (maxId ?? defaultPresets.length - 1) + 1;
  }
}
