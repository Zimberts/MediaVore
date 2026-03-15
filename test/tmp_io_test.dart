import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('temp dir create', () async {
    print('before createTemp');
    final tmp = await Directory.systemTemp.createTemp('mediavore_test');
    print('after createTemp: ${tmp.path}');
    final f = File('${tmp.path}/test.txt');
    await f.writeAsString('hello');
    print('wrote file, length ${await f.length()}');
    await tmp.delete(recursive: true);
  });
}
