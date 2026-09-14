import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:doctorfilter/domain/entities/filter_preset.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'doctorfilter_v2.db';
  static const int _dbVersion = 1;

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
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePresets (
        id INTEGER PRIMARY KEY,
        name_key TEXT NOT NULL,
        kelvin INTEGER NOT NULL,
        red INTEGER NOT NULL,
        green INTEGER NOT NULL,
        blue INTEGER NOT NULL,
        alpha INTEGER NOT NULL,
        brightness INTEGER NOT NULL,
        icon_identifier TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        is_pro_only INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insert 7 classic default presets
    final batch = db.batch();
    for (final preset in defaultPresets) {
      batch.insert(tablePresets, _presetToMap(preset));
    }
    await batch.commit(noResult: true);
  }

  static const List<FilterPreset> defaultPresets = [
    FilterPreset(
      id: 0,
      nameKey: 'gunes',
      kelvin: 5500,
      red: 255,
      green: 219,
      blue: 186,
      alpha: 25,
      brightness: 195,
      iconIdentifier: 'gunes',
    ),
    FilterPreset(
      id: 1,
      nameKey: 'florasan',
      kelvin: 4200,
      red: 255,
      green: 193,
      blue: 132,
      alpha: 50,
      brightness: 195,
      iconIdentifier: 'florasan',
    ),
    FilterPreset(
      id: 2,
      nameKey: 'lamba',
      kelvin: 3200,
      red: 255,
      green: 169,
      blue: 87,
      alpha: 75,
      brightness: 195,
      iconIdentifier: 'lamba',
    ),
    FilterPreset(
      id: 3,
      nameKey: 'ay',
      kelvin: 2200,
      red: 255,
      green: 137,
      blue: 18,
      alpha: 110,
      brightness: 180,
      iconIdentifier: 'ay',
    ),
    FilterPreset(
      id: 4,
      nameKey: 'mum',
      kelvin: 1400,
      red: 255,
      green: 126,
      blue: 0,
      alpha: 120,
      brightness: 170,
      iconIdentifier: 'mum',
    ),
    FilterPreset(
      id: 5,
      nameKey: 'kitap',
      kelvin: 2700,
      red: 250,
      green: 210,
      blue: 160,
      alpha: 65,
      brightness: 160,
      iconIdentifier: 'kitap',
    ),
    FilterPreset(
      id: 6,
      nameKey: 'agac',
      kelvin: 3500,
      red: 180,
      green: 220,
      blue: 140,
      alpha: 70,
      brightness: 175,
      iconIdentifier: 'agac',
    ),
  ];

  static Map<String, dynamic> _presetToMap(FilterPreset preset) {
    return {
      'id': preset.id,
      'name_key': preset.nameKey,
      'kelvin': preset.kelvin,
      'red': preset.red,
      'green': preset.green,
      'blue': preset.blue,
      'alpha': preset.alpha,
      'brightness': preset.brightness,
      'icon_identifier': preset.iconIdentifier,
      'is_custom': preset.isCustom ? 1 : 0,
      'is_pro_only': preset.isProOnly ? 1 : 0,
    };
  }

  static FilterPreset presetFromMap(Map<String, dynamic> map) {
    return FilterPreset(
      id: map['id'] as int,
      nameKey: map['name_key'] as String,
      kelvin: map['kelvin'] as int,
      red: map['red'] as int,
      green: map['green'] as int,
      blue: map['blue'] as int,
      alpha: map['alpha'] as int,
      brightness: map['brightness'] as int,
      iconIdentifier: (map['icon_identifier'] as String?) ?? '',
      isCustom: (map['is_custom'] as int? ?? 0) == 1,
      isProOnly: (map['is_pro_only'] as int? ?? 0) == 1,
    );
  }

  Future<List<FilterPreset>> getAllPresets() async {
    final db = await database;
    final maps = await db.query(tablePresets, orderBy: 'id ASC');
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

  Future<void> resetToDefaults() async {
    final db = await database;
    final batch = db.batch();
    batch.delete(tablePresets);
    for (final preset in defaultPresets) {
      batch.insert(tablePresets, _presetToMap(preset));
    }
    await batch.commit(noResult: true);
  }
}
