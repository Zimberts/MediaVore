import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockAchievementRepository mockRepo;

  setUp(() {
    mockRepo = MockAchievementRepository();
    when(
      () => mockRepo.getAchievements(),
    ).thenAnswer((_) async => <Achievement>[]);
    when(
      () => mockRepo.watchAchievements(),
    ).thenAnswer((_) => Stream.value(<Achievement>[]));
    when(() => mockRepo.clearAchievements()).thenAnswer((_) async {});
    when(
      () => mockRepo.unlockAchievement(any(), any()),
    ).thenAnswer((_) async {});
  });

  test('AchievementProvider initializes and refreshes without error', () async {
    final provider = AchievementProvider(mockRepo);

    await Future.delayed(Duration.zero);

    expect(provider.achievements, isA<List>());

    await provider.refresh();
    expect(provider.achievements, isA<List>());
  });
}
