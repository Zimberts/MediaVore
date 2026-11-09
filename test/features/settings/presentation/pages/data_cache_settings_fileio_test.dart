import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';

import '../../../../helpers/fake_file_picker.dart';

void main() {
  test('FilePicker + ZIP file -> ExportEnvelope parsing', () async {
    // create temp file with export envelope ZIP
    final tmp = await Directory.systemTemp.createTemp('mediavore_io_test');
    final file = File('${tmp.path}${Platform.pathSeparator}export.zip');

    final envelopeObj = ExportEnvelope(
      version: 1,
      exportedAt: DateTime.now(),
      seen: [
        SeenItemModel(
          tmdbId: 1,
          type: 'movie',
          title: 'Test Movie',
          posterPath: null,
          seenDate: DateTime.now(),
          seasonNumber: null,
          episodeNumber: null,
          runtime: null,
          genres: null,
        ),
      ],
      likes: [],
      notifications: [],
      lists: {},
    );

    final zipBytes = envelopeObj.toZipBytes();
    await file.writeAsBytes(zipBytes);

    final fake = FakeFilePickerPlatform()
      ..files = [LocalPlatformFile(file.path)];
    FilePickerPlatform.instance = fake;

    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    expect(picked, isNotNull);
    expect(picked!.path, equals(file.path));
    expect(picked.name, equals('export.zip'));

    final bytes = await picked.readAsBytes();
    final parsed = ExportEnvelope.fromZipBytes(bytes);

    expect(parsed.version, equals(1));
    expect(parsed.seen, isNotEmpty);
    expect(parsed.seen.first.tmdbId, equals(1));

    // cleanup
    await tmp.delete(recursive: true);
  });
}
