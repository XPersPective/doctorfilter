import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/errors/result.dart';
import 'package:doctorfilter/data/datasources/native/platform_channel_datasource.dart';
import 'package:doctorfilter/domain/entities/filter_config.dart';
import 'package:doctorfilter/domain/repositories/i_filter_repository.dart';
import 'package:doctorfilter/presentation/providers/core_providers.dart';
import 'package:doctorfilter/presentation/providers/filter_provider.dart';

/// Records what reached the repository, so the tests can assert on the thing
/// that actually matters: what would have been written to disk.
class _FakeFilterRepository implements IFilterRepository {
  _FakeFilterRepository({FilterConfig? initial})
      : stored = initial ?? FilterConfig.initial();

  FilterConfig stored;
  bool permissionGranted = true;

  final List<FilterConfig> persisted = [];
  final List<FilterConfig> appliedToPlatform = [];
  int permissionRequests = 0;
  int flushes = 0;

  final _events = StreamController<NativeFilterEvent>.broadcast();

  void emit(NativeFilterEvent event) => _events.add(event);

  @override
  Future<Result<FilterConfig>> loadConfig() async => Result.success(stored);

  @override
  void persist(FilterConfig config) => persisted.add(config);

  @override
  Future<void> flush() async => flushes++;

  @override
  Future<Result<void>> applyToPlatform(FilterConfig config) async {
    appliedToPlatform.add(config);
    return const Result.success(null);
  }

  @override
  Future<Result<bool>> checkOverlayPermission() async =>
      Result.success(permissionGranted);

  @override
  Future<Result<void>> requestOverlayPermission() async {
    permissionRequests++;
    return const Result.success(null);
  }

  @override
  Stream<NativeFilterEvent> get nativeEvents => _events.stream;

  void dispose() => _events.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeFilterRepository repository;
  late ProviderContainer container;

  FilterNotifier notifier() => container.read(filterProvider.notifier);
  FilterState read() => container.read(filterProvider);

  /// Lets the notifier finish its async startup (and any event delivery) before
  /// the test acts. Several pumps, because startup awaits more than one future.
  Future<void> ready() async {
    container.read(filterProvider); // providers are lazy; force construction
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    repository = _FakeFilterRepository(
      initial: FilterConfig(
        isEnabled: true,
        activePresetId: 3,
        kelvin: 2700,
        densityPercent: 50,
        extraDimPercent: 30,
        isNotificationEnabled: true,
        isScheduleEnabled: false,
      ),
    );
    container = ProviderContainer(overrides: [
      filterRepositoryProvider.overrideWithValue(repository),
    ]);
  });

  tearDown(() {
    container.dispose();
    repository.dispose();
  });

  group('settings survive — the bug this design exists to prevent', () {
    test('every change persists a complete configuration, never a fragment', () async {
      await ready();
      notifier().setKelvin(2200);
      notifier().setDensity(60);
      notifier().setExtraDim(40);

      // Each write carries all three axes: nothing can be lost by a later write
      // reading a stale record, because no write reads at all.
      final last = repository.persisted.last;
      expect(last.kelvin, 2200);
      expect(last.densityPercent, 60);
      expect(last.extraDimPercent, 40);
    });

    test('a rapid drag never regresses an earlier axis', () async {
      await ready();
      notifier().setDensity(70);
      for (var k = 2000; k <= 2500; k += 50) {
        notifier().setKelvin(k);
      }
      expect(read().config.densityPercent, 70);
      expect(repository.persisted.last.densityPercent, 70);
    });

    test('config is read from disk once, not re-read per change', () async {
      await ready();
      repository.stored = repository.stored.copyWith(kelvin: 9999);
      notifier().setDensity(10);
      // Memory is authoritative: a change on disk behind our back is ignored.
      expect(read().config.kelvin, 2700);
    });
  });

  group('undo', () {
    test('nothing to undo on a fresh state', () async {
      await ready();
      expect(read().canUndo, isFalse);
      notifier().undo();
      expect(read().config.kelvin, 2700);
    });

    test('steps back to the value before the change', () async {
      await ready();
      notifier().setKelvin(2000);
      expect(read().canUndo, isTrue);

      notifier().undo();
      expect(read().config.kelvin, 2700);
    });

    test('a drag collapses into a single undo step', () async {
      await ready();
      for (var k = 2600; k >= 2000; k -= 50) {
        notifier().setKelvin(k);
      }
      notifier().undo();
      expect(read().config.kelvin, 2700, reason: 'one gesture should be one undo');
    });

    test('undo restores axes but never switches the filter off', () async {
      await ready();
      notifier().setDensity(10);
      notifier().undo();
      expect(read().config.isEnabled, isTrue);
      expect(read().config.densityPercent, 50);
    });

    test('undone state is persisted, not just shown', () async {
      await ready();
      notifier().setExtraDim(70);
      notifier().undo();
      expect(repository.persisted.last.extraDimPercent, 30);
    });
  });

  group('active preset tracking', () {
    test('adjusting an axis by hand detaches from the preset', () async {
      await ready();
      expect(read().config.activePresetId, 3);
      notifier().setKelvin(2400);
      expect(read().config.activePresetId, isNot(3));
    });

    test('adopting a preset sets the active id and is undoable', () async {
      await ready();
      notifier().adopt(read().config.copyWith(activePresetId: 6, kelvin: 1850));
      expect(read().config.activePresetId, 6);

      notifier().undo();
      expect(read().config.activePresetId, 3);
      expect(read().config.kelvin, 2700);
    });
  });

  group('native events', () {
    test('a toggle from the notification updates and persists state', () async {
      await ready();
      repository.emit(const NativeFilterToggled(false));
      await ready();
      expect(read().config.isEnabled, isFalse);
      expect(repository.persisted.last.isEnabled, isFalse);
    });

    test('an axis change from the notification is adopted', () async {
      await ready();
      repository.emit(const NativeAxisChanged(densityPercent: 75));
      await ready();
      expect(read().config.densityPercent, 75);
    });
  });

  group('permission gate', () {
    test('turning on without permission asks for it and does not claim success',
        () async {
      repository.permissionGranted = false;
      repository.stored = repository.stored.copyWith(isEnabled: false);
      await ready();

      await notifier().toggle();

      expect(repository.permissionRequests, 1);
      expect(read().config.isEnabled, isFalse);
      expect(read().hasOverlayPermission, isFalse);
      expect(read().errorKey, isNotNull);
    });
  });

  group('restoring the overlay at launch', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('Windows redraws a filter that was saved as on', () async {
      // The overlay window dies with the process there; without this the app
      // said "Filter on" over an untinted desktop after a restart.
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await ready();
      expect(repository.appliedToPlatform, hasLength(1));
      expect(repository.appliedToPlatform.single.kelvin, 2700);
    });

    test('Android leaves it to the service that outlives the app', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await ready();
      expect(repository.appliedToPlatform, isEmpty);
    });
  });
}

