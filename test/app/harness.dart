// App-level test harness (#462): boots the real app (real DI, real Isar,
// real providers) against a fake TMDB server. Journeys that cross screens go
// in `test/app/journeys/`; see `.ai/rules/testing.md`.
import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/main.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:workmanager_android/workmanager_android.dart';

import '../helpers/fake_image_cache.dart';
import '../helpers/fake_tmdb.dart';

/// App booted by the running test.
TestApp? _current;

/// Well-formed TMDB v3 key (32 hex digits) used by default.
const String testTmdbCredential = '0123456789abcdef0123456789abcdef';

/// Initial state of the app, written before the first frame: preferences and
/// TMDB key directly in their stores, lists and history through the real
/// repository.
class AppSeed {
  const AppSeed({
    this.tmdbCredential = testTmdbCredential,
    this.prefs = const {},
    this.lists = const {},
    this.seen = const [],
  });

  /// Stored TMDB credential; null for a first launch without a key.
  final String? tmdbCredential;

  /// Initial SharedPreferences values (settings).
  final Map<String, Object> prefs;

  /// Lists to create, by name, with their items in order.
  final Map<String, List<MediaItem>> lists;

  /// Seen history.
  final List<SeenItem> seen;
}

/// The app booted by [bootTestApp].
class TestApp {
  TestApp._(this.tmdb, this.images, this.workmanager, this._links, this._dir);

  /// Fake TMDB server answering every API request.
  final FakeTmdb tmdb;

  /// Records the images the app loaded (always a transparent PNG).
  final FakeImageService images;

  /// Records the background sync registrations.
  final FakeWorkmanager workmanager;

  final StreamController<String> _links;
  final Directory _dir;

  /// Real repository, for assertions on persisted state.
  MediaRepository get repository => locator<MediaRepository>();

  /// Delivers [uri] as an incoming deep link (`app_links`).
  Future<void> openLink(WidgetTester tester, Uri uri) async {
    _links.add(uri.toString());
    await pumpUntilSettled(tester);
  }
}

/// Boots the real app: `bootstrapServices` (real DI, real Isar in a
/// disposable `test/tmp_app_*` directory) then `MediaVoreApp`, with TMDB
/// answered by [tmdb] (a default [FakeTmdb] when null).
///
/// Platform plugins are neutralised: path_provider, secure storage,
/// SharedPreferences, workmanager, app_links and the image cache (no
/// network, no sqflite). Everything is torn down at
/// the end of the test, which fails if a TMDB request was not covered.
Future<TestApp> bootTestApp(
  WidgetTester tester, {
  AppSeed seed = const AppSeed(),
  FakeTmdb? tmdb,
}) async {
  final server = tmdb ?? FakeTmdb();
  final dir = Directory(
    '${Directory.current.path}/test/tmp_app_'
    '${DateTime.now().microsecondsSinceEpoch}',
  )..createSync(recursive: true);

  _fakePlatform(dir.path);
  // rootBundle caches asset loads across tests: a load a previous test left
  // pending on its fake clock would never complete in this one (big assets,
  // such as the achievement definitions, are decoded off the main isolate).
  rootBundle.clear();
  SharedPreferences.setMockInitialValues(seed.prefs);
  FlutterSecureStorage.setMockInitialValues({
    if (seed.tmdbCredential != null)
      TmdbCredentialStore.secureStorageKey: seed.tmdbCredential!,
  });
  final workmanager = FakeWorkmanager();
  WorkmanagerPlatform.instance = workmanager;
  final images = FakeImageService();
  CachedNetworkImageProvider.defaultCacheManager = fakeImageCacheManager(
    images,
    Directory('${dir.path}/images'),
  );
  final links = _mockAppLinks(tester);

  // Safety net when a test skips [disposeTestApp]: no scratch dir leaks.
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  final app = _current = TestApp._(server, images, workmanager, links, dir);
  try {
    await tester.runAsync(() async {
      await _initializeIsarCore();
      await bootstrapServices(tmdbHttpClientAdapter: server);
      await _applySeed(seed);
    });
    await tester.pumpWidget(const MediaVoreApp());
    await pumpUntilSettled(tester);
  } catch (_) {
    // Close what the failed boot opened before reporting it.
    try {
      await disposeTestApp(tester, verifyTmdb: false);
    } catch (e) {
      debugPrint('[bootTestApp] teardown after a failed boot failed: $e');
    }
    rethrow;
  }
  return app;
}

Future<void>? _isarCore;

/// Loads the Isar native library once per test process.
/// A failed load is retried by the next test.
Future<void> _initializeIsarCore() => _isarCore ??=
    Isar.initializeIsarCore(download: true).catchError((Object e) {
      _isarCore = null;
      throw e;
    });

/// Fakes path_provider (scratch [root]); restores the previous instances and
/// clears the storage mocks at the end of the test.
///
/// The image cache is not restored: reading the default would build the real
/// `DefaultCacheManager` (sqflite on macOS, iOS and Android). It is parked on
/// a fake in the system temporary directory instead, so that a later test in
/// the same file never writes into a deleted scratch dir.
void _fakePlatform(String root) {
  final pathProvider = PathProviderPlatform.instance;
  final workmanager = WorkmanagerPlatform.instance;
  PathProviderPlatform.instance = _FakePathProvider(root);
  addTearDown(() {
    PathProviderPlatform.instance = pathProvider;
    WorkmanagerPlatform.instance = workmanager;
    CachedNetworkImageProvider.defaultCacheManager = fakeImageCacheManager(
      FakeImageService(),
      Directory('${Directory.systemTemp.path}/mediavore_test_images'),
    );
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
}

/// Tears down the app booted by [bootTestApp]: unmounts it, flushes the
/// pending timers, closes and deletes the database, resets the DI. Fails if
/// a TMDB request was not covered by the fake, unless [verifyTmdb] is false.
///
/// Must run inside the test body (before flutter_test checks that no timer
/// is pending); [testApp] does it.
Future<void> disposeTestApp(
  WidgetTester tester, {
  bool verifyTmdb = true,
}) async {
  final app = _current;
  if (app == null) return;
  _current = null;

  // Let pending loads finish: providers notify when their I/O completes.
  await pumpUntilSettled(tester);
  // Unmount, then run out the timers left by the tree (image cache cleanup,
  // auto-dismissed messages).
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(minutes: 1));

  if (locator.isRegistered<Isar>()) {
    final isar = locator<Isar>();
    if (isar.isOpen) {
      await _realAwait(tester, isar.close(deleteFromDisk: true));
    }
  }
  await _realAwait(tester, Future.sync(locator.reset));
  await app._links.close();
  if (app._dir.existsSync()) app._dir.deleteSync(recursive: true);
  if (!verifyTmdb) return;
  expect(
    app.tmdb.unhandled,
    isEmpty,
    reason: 'TMDB requests not covered by FakeTmdb',
  );
}

/// [testWidgets] on the booted app: [bootTestApp], [body], then
/// [disposeTestApp] even when [body] fails. A failure of [body] is the one
/// reported: teardown problems never hide it.
void testApp(
  String description,
  Future<void> Function(WidgetTester tester, TestApp app) body, {
  AppSeed seed = const AppSeed(),
  FakeTmdb Function()? tmdb,
  Timeout? timeout,
}) {
  testWidgets(description, (tester) async {
    final app = await bootTestApp(tester, seed: seed, tmdb: tmdb?.call());
    try {
      await body(tester, app);
    } catch (_) {
      try {
        await disposeTestApp(tester, verifyTmdb: false);
      } catch (e) {
        debugPrint('[testApp] teardown after a failure also failed: $e');
      }
      rethrow;
    }
    await disposeTestApp(tester);
  }, timeout: timeout);
}

/// Waits for [future], which completes on real I/O (Isar), while letting
/// the fake-time microtasks it depends on run.
Future<T> _realAwait<T>(WidgetTester tester, Future<T> future) async {
  var done = false;
  late T result;
  Object? error;
  StackTrace? stack;
  unawaited(
    future.then(
      (value) {
        result = value;
        done = true;
      },
      onError: (Object e, StackTrace s) {
        error = e;
        stack = s;
        done = true;
      },
    ),
  );
  for (var i = 0; i < 1000 && !done; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  if (error != null) Error.throwWithStackTrace(error!, stack!);
  if (!done) fail('timed out waiting for real I/O');
  return result;
}

Future<void> _applySeed(AppSeed seed) async {
  final repository = locator<MediaRepository>();
  final existing = await repository.getAllListNames();
  for (final entry in seed.lists.entries) {
    if (!existing.contains(entry.key)) await repository.createList(entry.key);
    await repository.addAllToList(entry.value, entry.key);
  }
  if (seed.seen.isNotEmpty) await repository.markManyAsSeen(seed.seen);
}

/// Pumps frames and lets real I/O (Isar) complete until the app is idle:
/// no scheduled frame and no TMDB request in flight for [quietSteps]
/// consecutive steps.
///
/// Each step gives real time to native I/O ([realGap]) then advances fake
/// time by [step]. Bounded by [timeout] of fake time: an infinite animation
/// (spinner, shimmer) does not block, the pump just stops at the bound.
Future<void> pumpUntilSettled(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 50),
  Duration timeout = const Duration(seconds: 10),
  Duration realGap = const Duration(milliseconds: 5),
  int quietSteps = 10,
}) async {
  final adapter = _current?.tmdb;
  var quiet = 0;
  for (var elapsed = Duration.zero; elapsed < timeout; elapsed += step) {
    // Isar answers on a native port, outside fake time.
    await tester.runAsync(() => Future<void>.delayed(realGap));
    await tester.pump(step);
    final busy =
        tester.binding.hasScheduledFrame || (adapter?.inFlight ?? 0) > 0;
    quiet = busy ? 0 : quiet + 1;
    if (quiet >= quietSteps) return;
  }
}

/// Selects [tab] in the tab bar.
Future<void> goToTab(WidgetTester tester, AppTab tab) async {
  await tester.tap(find.byKey(ValueKey(tab)));
  await pumpUntilSettled(tester);
}

/// Opens the detail page of the title [tmdbId], as a tap on a poster does.
Future<void> openDetail(
  WidgetTester tester,
  int tmdbId, {
  MediaType type = MediaType.movie,
}) async {
  final context = tester.element(find.byType(MainPage));
  unawaited(
    MediaDetailPage.show(
      context,
      MediaItem(
        id: tmdbId,
        title: '',
        overview: '',
        releaseDate: '',
        mediaType: type,
      ),
    ),
  );
  await pumpUntilSettled(tester);
}

/// Records the background sync registrations instead of scheduling them.
///
/// Implements [WorkmanagerAndroid] so that `Workmanager` keeps it on every
/// host (it replaces any other implementation by the host's one: on a Linux
/// CI runner, systemd timers).
class FakeWorkmanager extends Fake
    with MockPlatformInterfaceMixin
    implements WorkmanagerAndroid {
  final List<String> registered = [];
  bool initialized = false;

  @override
  Future<void> initialize(
    Function callbackDispatcher, {
    bool isInDebugMode = false,
  }) async => initialized = true;

  @override
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    Duration? flexInterval,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingPeriodicWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async => registered.add(uniqueName);

  @override
  Future<void> registerOneOffTask(
    String uniqueName,
    String taskName, {
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    bool expedited = false,
    ExistingWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    OutOfQuotaPolicy? outOfQuotaPolicy,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async => registered.add(uniqueName);
}

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  String _sub(String name) =>
      (Directory('$root/$name')..createSync(recursive: true)).path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _sub('documents');

  @override
  Future<String?> getApplicationSupportPath() async => _sub('support');

  @override
  Future<String?> getApplicationCachePath() async => _sub('cache');

  @override
  Future<String?> getTemporaryPath() async => _sub('tmp');
}

/// No initial link; links pushed on the returned controller reach the app.
StreamController<String> _mockAppLinks(WidgetTester tester) {
  const messages = MethodChannel('com.llfbandit.app_links/messages');
  const events = EventChannel('com.llfbandit.app_links/events');
  final messenger = tester.binding.defaultBinaryMessenger;
  final links = StreamController<String>.broadcast();
  StreamSubscription<String>? forward;
  messenger.setMockMethodCallHandler(messages, (call) async => null);
  messenger.setMockStreamHandler(
    events,
    MockStreamHandler.inline(
      onListen: (arguments, sink) {
        forward = links.stream.listen(sink.success);
      },
      onCancel: (arguments) {
        unawaited(forward?.cancel());
      },
    ),
  );
  addTearDown(() {
    messenger.setMockMethodCallHandler(messages, null);
    messenger.setMockStreamHandler(events, null);
  });
  return links;
}
