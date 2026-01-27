import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/mocks.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';

void main() {
  group('Platform integrations (basic)', () {
    test('remote data source factory creates instance', () async {
      final mockDio = MockDio();
      // Construct using factory; ensure it doesn't throw when provided
      // a Dio instance and explicit token.
      final ds = MediaRemoteDataSource(dio: mockDio, apiToken: 'test_token');
      expect(ds, isA<MediaRemoteDataSource>());
    });

    test('mock remote datasource can be stubbed', () async {
      final mockRemote = MockMediaRemoteDataSource();
      when(() => mockRemote.searchMedia(any())).thenAnswer((_) async => []);
      final res = await mockRemote.searchMedia('query');
      expect(res, isEmpty);
      verify(() => mockRemote.searchMedia('query')).called(1);
    });
  });
}
