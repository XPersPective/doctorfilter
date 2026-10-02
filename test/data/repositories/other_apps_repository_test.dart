import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctorfilter/data/repositories/other_apps_repository.dart';

String _catalogue(List<Object?> apps) => jsonEncode({'schema': 1, 'apps': apps});

Map<String, Object?> _app(String id, {String? pkg, int order = 0, String? icon}) => {
      'id': id,
      'androidPackage': pkg ?? 'com.example.$id',
      'icon': ?icon,
      'name': {'en': 'Name $id', 'tr': 'Ad $id'},
      'description': {'en': 'About $id'},
      'order': order,
    };

void main() {
  // Unreachable on purpose: every network attempt fails fast.
  const offline = 'https://127.0.0.1:9/apps.json';

  Future<OtherAppsRepository> repo(Map<String, Object> prefs, DateTime now) async {
    SharedPreferences.setMockInitialValues(prefs);
    return OtherAppsRepository(
      url: offline,
      prefs: await SharedPreferences.getInstance(),
      timeout: const Duration(seconds: 2),
      now: () => now,
    );
  }

  final now = DateTime(2026, 10, 2, 12);

  test('fresh cache: sorted, own app hidden, malformed entries skipped', () async {
    final r = await repo({
      'df_other_apps_cache': _catalogue([
        _app('b', order: 2),
        _app('self', pkg: 'com.crazypenguin.doctorfilter'),
        {'id': 'broken'}, // no store id, no name
        _app('bad_icon', icon: 'http://insecure/icon.png'),
        _app('a', order: 1),
      ]),
      'df_other_apps_cache_at': now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
    }, now);

    final apps = await r.load(ownPackage: 'com.crazypenguin.doctorfilter');
    expect(apps.map((a) => a.id), ['a', 'b']);
    expect(apps.first.nameIn('tr'), 'Ad a');
    expect(apps.first.descriptionIn('tr'), 'About a'); // falls back to en
    expect(apps.first.storeUrl(isIos: false),
        'https://play.google.com/store/apps/details?id=com.example.a');
    expect(apps.first.storeUrl(isIos: true), isNull);
  });

  test('stale cache is still used when the network is unreachable', () async {
    final r = await repo({
      'df_other_apps_cache': _catalogue([_app('x')]),
      'df_other_apps_cache_at': now.subtract(const Duration(days: 9)).millisecondsSinceEpoch,
    }, now);
    expect((await r.load(ownPackage: 'p')).map((a) => a.id), ['x']);
  });

  test('nothing cached and offline: empty list, never throws', () async {
    final r = await repo({}, now);
    expect(await r.load(ownPackage: 'p'), isEmpty);
  });

  test('unknown schema is ignored rather than half-read', () async {
    final r = await repo({
      'df_other_apps_cache': jsonEncode({'schema': 2, 'apps': [_app('x')]}),
      'df_other_apps_cache_at': now.millisecondsSinceEpoch,
    }, now);
    expect(await r.load(ownPackage: 'p'), isEmpty);
  });
}
