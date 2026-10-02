import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// One entry of the developer's app catalogue (`apps.json`, schema 1 — the
/// same file the napp_kit template apps read; see ORTAK_UYGULAMA_STANDARDI 3.6).
class OtherApp {
  const OtherApp({
    required this.id,
    required this.name,
    required this.description,
    this.androidPackage,
    this.appStoreId,
    this.iconUrl,
    this.order = 0,
  });

  final String id;
  final String? androidPackage;
  final String? appStoreId;
  final String? iconUrl;
  final Map<String, String> name;
  final Map<String, String> description;
  final int order;

  /// Null when the entry is malformed — one bad record never hides the rest.
  static OtherApp? tryParse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'];
    if (id is! String || id.trim().isEmpty) return null;
    final android = raw['androidPackage'];
    final appStore = raw['appStoreId'];
    if (android is! String? || appStore is! String?) return null;
    if ((android ?? '').isEmpty && (appStore ?? '').isEmpty) return null;
    final icon = raw['icon'];
    if (icon is! String? || (icon != null && !icon.startsWith('https://'))) {
      return null;
    }
    final name = _localized(raw['name']);
    final description = _localized(raw['description']);
    if (name == null || description == null) return null;
    final order = raw['order'];
    return OtherApp(
      id: id,
      androidPackage: (android ?? '').isEmpty ? null : android,
      appStoreId: (appStore ?? '').isEmpty ? null : appStore,
      iconUrl: icon,
      name: name,
      description: description,
      order: order is int ? order : 0,
    );
  }

  static Map<String, String>? _localized(Object? raw) {
    if (raw is! Map<String, dynamic> || raw.isEmpty) return null;
    final out = <String, String>{};
    for (final e in raw.entries) {
      if (e.value is! String || (e.value as String).trim().isEmpty) return null;
      out[e.key] = e.value as String;
    }
    return out;
  }

  String nameIn(String lang) => _pick(name, lang) ?? id;
  String descriptionIn(String lang) => _pick(description, lang) ?? '';

  static String? _pick(Map<String, String> map, String lang) =>
      map[lang] ?? map[lang.split(RegExp('[-_]')).first] ?? map['en'] ??
      (map.isEmpty ? null : map.values.first);

  /// The store page for this platform, or null if it is not on that store.
  String? storeUrl({required bool isIos}) => isIos
      ? (appStoreId == null ? null : 'https://apps.apple.com/app/id$appStoreId')
      : (androidPackage == null
          ? null
          : 'https://play.google.com/store/apps/details?id=$androidPackage');

  Map<String, Object?> toJson() => {
        'id': id,
        'androidPackage': androidPackage,
        'appStoreId': appStoreId,
        'icon': iconUrl,
        'name': name,
        'description': description,
        'order': order,
      };
}

/// Fetches the catalogue: network → cache (24 h, or any age when offline) →
/// empty. Never throws; the current app is never listed.
class OtherAppsRepository {
  OtherAppsRepository({
    required this.url,
    required this.prefs,
    this.timeout = const Duration(seconds: 6),
    this.cacheTtl = const Duration(hours: 24),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final String url;
  final SharedPreferences prefs;
  final Duration timeout;
  final Duration cacheTtl;
  final DateTime Function() _now;

  static const _cacheKey = 'df_other_apps_cache';
  static const _cacheAtKey = 'df_other_apps_cache_at';
  static const supportedSchema = 1;

  Future<List<OtherApp>> load({required String ownPackage}) async {
    final cachedAt = prefs.getInt(_cacheAtKey);
    final cached = _decode(prefs.getString(_cacheKey));
    final fresh = cachedAt != null &&
        _now().difference(DateTime.fromMillisecondsSinceEpoch(cachedAt)) < cacheTtl;
    if (cached != null && fresh) return _visible(cached, ownPackage);

    try {
      final body = await _get(url).timeout(timeout);
      final apps = _decode(body);
      if (apps == null) throw const FormatException('apps.json schema');
      await prefs.setString(_cacheKey, body);
      await prefs.setInt(_cacheAtKey, _now().millisecondsSinceEpoch);
      return _visible(apps, ownPackage);
    } catch (_) {
      return _visible(cached ?? const [], ownPackage);
    }
  }

  static List<OtherApp> _visible(List<OtherApp> apps, String ownPackage) =>
      apps.where((a) => a.androidPackage != ownPackage).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  /// Parses `apps.json`; null if the document itself is unusable.
  static List<OtherApp>? _decode(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      final doc = jsonDecode(body);
      if (doc is! Map<String, dynamic> || doc['schema'] != supportedSchema) {
        return null;
      }
      final list = doc['apps'];
      if (list is! List) return null;
      return [for (final raw in list) ?OtherApp.tryParse(raw)];
    } on FormatException {
      return null;
    }
  }

  static Future<String> _get(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}
