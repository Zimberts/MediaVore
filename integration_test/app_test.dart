// Device integration test entry point (#473): replays the shared app
// journeys against real Android plugins (native Isar, path_provider,
// secure storage, workmanager) while keeping TMDB mocked.
import 'package:integration_test/integration_test.dart';

import '../test/app/journeys/discover_add_test.dart';
import '../test/app/journeys/export_import_test.dart';
import '../test/app/journeys/movie_seen_test.dart';
import '../test/helpers/embedded_fixtures.dart';
import '../test/helpers/fixture_reader.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerTestFixtures(
    text: embeddedTextFixtures,
    binaryBase64: embeddedBinaryFixturesBase64,
  );

  registerDiscoverAddJourney();
  registerMovieSeenJourney();
  registerExportImportJourney();
}
