import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mediavore/features/achievements/domain/repositories/achievement_repository.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';

import '../../../../helpers/fake_file_picker.dart';

class MockAchievementRepo extends Mock implements AchievementRepository {}

class MockRepo extends Mock implements MediaRepository {}

void main() {
  test('setup sanity', () async {
    registerFallbackValue(ImportMode.append);
    registerFallbackValue((double p, String s) {});

    final mockRepo = MockRepo();
    final mockAchievementRepo = MockAchievementRepo();

    when(
      () => mockAchievementRepo.getAchievements(),
    ).thenAnswer((_) async => <Achievement>[]);
    when(
      () => mockAchievementRepo.watchAchievements(),
    ).thenAnswer((_) => Stream<List<Achievement>>.value(<Achievement>[]));
    when(
      () => mockAchievementRepo.clearAchievements(),
    ).thenAnswer((_) async {});
    when(
      () => mockAchievementRepo.unlockAchievement(any(), any()),
    ).thenAnswer((_) async {});

    when(() => mockRepo.getSeenItems()).thenAnswer((_) async => <SeenItem>[]);
    when(() => mockRepo.getLikedEntries()).thenAnswer((_) async => <String>[]);

    FilePickerPlatform.instance = FakeFilePickerPlatform();

    // reach here means setup is fine
    expect(true, isTrue);
  });
}
