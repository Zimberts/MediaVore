import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/cache/cache_warmup_policy.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/features/search/data/services/cache_warmup_service.dart';
import 'package:mediavore/features/search/data/services/repository_lifecycle.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

class MockCacheWarmupService extends Mock implements CacheWarmupService {}

class MockCacheWarmupPolicy extends Mock implements CacheWarmupPolicy {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  late MockMediaCache cache;
  late MockCacheWarmupService warmup;

  RepositoryLifecycle build({
    CacheWarmupPolicy? policy,
    LocaleService? locale,
  }) => RepositoryLifecycle(
    cache: cache,
    warmup: warmup,
    warmupPolicy: policy,
    localeService: locale,
  );

  setUp(() {
    cache = MockMediaCache();
    warmup = MockCacheWarmupService();
    when(() => cache.init()).thenAnswer((_) async {});
    when(() => cache.clearAll()).thenAnswer((_) async {});
    when(() => warmup.run()).thenAnswer((_) async => true);
  });

  group('RepositoryLifecycle.ensureInitialized', () {
    test('should wait until the cache is open', () async {
      final opened = Completer<void>();
      when(() => cache.init()).thenAnswer((_) => opened.future);
      final lifecycle = build();

      var ready = false;
      unawaited(lifecycle.init());
      unawaited(lifecycle.ensureInitialized().then((_) => ready = true));
      await pumpEventQueue();
      expect(ready, isFalse);

      opened.complete();
      await pumpEventQueue();
      expect(ready, isTrue);
    });

    test('should not block forever when the cache fails to open', () async {
      when(() => cache.init()).thenThrow(Exception('corrupt'));
      final lifecycle = build();

      await lifecycle.init();

      await expectLater(lifecycle.ensureInitialized(), completes);
    });

    test('should be ready right away after skipInit', () async {
      final lifecycle = build()..skipInit();

      await expectLater(lifecycle.ensureInitialized(), completes);
      verifyNever(() => cache.init());
      verifyNever(() => warmup.run());
    });
  });

  group('RepositoryLifecycle.init warm-up', () {
    test('should start the warm-up without a policy', () async {
      await build().init();

      verify(() => warmup.run()).called(1);
    });

    test('should skip the warm-up when the policy throttles it', () async {
      final policy = MockCacheWarmupPolicy();
      when(policy.shouldRunAutomatically).thenReturn(false);

      await build(policy: policy).init();

      verifyNever(() => warmup.run());
    });

    test('should record a completed warm-up in the policy', () async {
      final policy = MockCacheWarmupPolicy();
      when(policy.shouldRunAutomatically).thenReturn(true);
      when(policy.markCompleted).thenAnswer((_) async {});

      await build(policy: policy).init();
      await pumpEventQueue();

      verify(policy.markCompleted).called(1);
    });

    test('should not record a cancelled warm-up', () async {
      final policy = MockCacheWarmupPolicy();
      when(policy.shouldRunAutomatically).thenReturn(true);
      when(() => warmup.run()).thenAnswer((_) async => false);

      await build(policy: policy).init();
      await pumpEventQueue();

      verifyNever(policy.markCompleted);
    });
  });

  group('RepositoryLifecycle language', () {
    late MockLocaleService locale;

    setUp(() {
      locale = MockLocaleService();
      when(() => locale.tmdbLanguage).thenReturn('fr-FR');
      when(() => locale.markCacheLanguage()).thenAnswer((_) async {});
    });

    test('should drop a cache filled in another language on init', () async {
      when(() => locale.isCacheLanguageStale).thenReturn(true);

      await build(locale: locale).init();

      verifyInOrder([
        () => warmup.cancel(),
        () => cache.clearAll(),
        () => locale.markCacheLanguage(),
      ]);
    });

    test('should keep the cache when the language did not change', () async {
      when(() => locale.isCacheLanguageStale).thenReturn(false);
      final lifecycle = build(locale: locale)..skipInit();

      expect(await lifecycle.applyLanguageChange(), isFalse);
      verifyNever(() => cache.clearAll());
      verifyNever(() => warmup.run());
    });

    test('should clear and refill once for concurrent changes', () async {
      var stale = true;
      when(() => locale.isCacheLanguageStale).thenAnswer((_) => stale);
      when(() => locale.markCacheLanguage()).thenAnswer((_) async {
        stale = false;
      });
      final lifecycle = build(locale: locale)..skipInit();

      final first = lifecycle.applyLanguageChange();
      final second = lifecycle.applyLanguageChange();

      expect(identical(first, second), isTrue);
      expect(await first, isTrue);
      verify(() => cache.clearAll()).called(1);
      verify(() => warmup.run()).called(1);
    });
  });
}
