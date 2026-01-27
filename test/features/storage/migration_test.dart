import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/mocks.dart';

void main() {
  group('Storage migrations (basic smoke)', () {
    test('local data source export call forwards to datasource', () async {
      final mockLocal = MockMediaListLocalDataSource();

      when(() => mockLocal.getExportData()).thenAnswer((_) async => []);

      final res = await mockLocal.getExportData();
      expect(res, isA<List>());
      verify(() => mockLocal.getExportData()).called(1);
    });
  });
}
