import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAchievementRepository mockRepository;
  late StreamController<List<Achievement>> controller;

  setUp(() {
    mockRepository = MockAchievementRepository();
    controller = StreamController<List<Achievement>>.broadcast();

    when(() => mockRepository.watchAchievements()).thenAnswer((_) => controller.stream);
    when(() => mockRepository.getAchievements()).thenAnswer((_) async => <Achievement>[]);
    when(() => mockRepository.clearAchievements()).thenAnswer((_) async => {});
    when(() => mockRepository.unlockAchievement(any(), any())).thenAnswer((_) async => {});
  });

  tearDown(() {
    controller.close();
  });

  test('clearAchievements calls repository.clearAchievements and refreshes', () async {
    final provider = AchievementProvider(mockRepository);

    // allow provider to initialize
    await Future<void>.delayed(Duration.zero);

    await provider.clearAchievements();

    verify(() => mockRepository.clearAchievements()).called(1);
    verify(() => mockRepository.getAchievements()).called(greaterThanOrEqualTo(1));
  });
}
