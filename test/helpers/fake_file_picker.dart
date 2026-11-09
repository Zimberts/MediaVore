import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus/share_plus.dart' show XFile;

/// In-memory [FilePickerPlatform] for tests.
///
/// Since file_picker 12, `FilePicker` is a final class of static methods that
/// delegate to [FilePickerPlatform.instance]: install a fake with
/// `FilePickerPlatform.instance = FakeFilePickerPlatform()`.
class FakeFilePickerPlatform extends FilePickerPlatform
    with MockPlatformInterfaceMixin {
  /// Files returned by [pickFile] (first one) and [pickFiles].
  List<PlatformFile> files = const [];

  /// Last arguments received by [saveFile].
  String? savedFileName;
  Uint8List? savedBytes;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => files.isEmpty ? null : files.first;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => files;

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    savedFileName = fileName;
    savedBytes = bytes;
    return Uri.file(fileName);
  }
}

/// [PlatformFile] backed by a local file, for tests.
base class LocalPlatformFile extends PlatformFile {
  LocalPlatformFile(String path) : _file = File(path);

  final File _file;

  @override
  String get name => _file.uri.pathSegments.last;

  @override
  Uri get uri => _file.uri;

  @override
  XFile get xFile => XFile(_file.path, name: name);

  @override
  int? lengthSync() => _file.existsSync() ? _file.lengthSync() : null;

  @override
  Future<int?> length() async => await _file.exists() ? _file.length() : null;

  @override
  Future<Uint8List> readAsBytes() => _file.readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() =>
      _file.openRead().map(Uint8List.fromList);
}
