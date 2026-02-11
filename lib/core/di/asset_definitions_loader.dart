import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mediavore/core/di/definitions_loader.dart';

@LazySingleton(as: DefinitionsLoader)
class AssetDefinitionsLoader implements DefinitionsLoader {
  static const _assetPath = 'assets/achievements/definitions.json';

  @override
  Future<List<Map<String, dynamic>>> load() async {
    final jsonStr = await rootBundle.loadString(_assetPath);
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
