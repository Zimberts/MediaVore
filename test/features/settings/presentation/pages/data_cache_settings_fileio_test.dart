import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';

class _FakePicker extends FilePicker {
  String? filePath;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    if (filePath == null) return null;
    final p = filePath!;
    final f = File(p);
    final size = await f.length();
    final pf = PlatformFile(
      name: p.split(Platform.pathSeparator).last,
      path: p,
      size: size,
    );
    return FilePickerResult([pf]);
  }
}

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

    final fake = _FakePicker()..filePath = file.path;
    FilePicker.platform = fake;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    expect(result, isNotNull);
    expect(result!.files.single.path, equals(file.path));

    final bytes = await File(result.files.single.path!).readAsBytes();
    final parsed = ExportEnvelope.fromZipBytes(bytes);

    expect(parsed.version, equals(1));
    expect(parsed.seen, isNotEmpty);
    expect(parsed.seen.first.tmdbId, equals(1));

    // cleanup
    await tmp.delete(recursive: true);
  });
}
