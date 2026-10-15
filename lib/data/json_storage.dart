import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/group.dart';

/// Persists the list of groups. Abstracted so tests can use an in-memory store.
abstract class GroupStore {
  Future<List<Group>> load();
  Future<void> save(List<Group> groups);
}

/// Stores all data in a single JSON file in the app documents directory.
class JsonStorage implements GroupStore {
  static const fileName = 'groupay_data.json';
  static const _version = 1;

  final Future<Directory> Function() _directory;

  JsonStorage({Future<Directory> Function()? directory})
      : _directory = directory ?? getApplicationDocumentsDirectory;

  Future<File> _file() async => File('${(await _directory()).path}/$fileName');

  @override
  Future<List<Group>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return [
      for (final g in data['groups'] as List? ?? const [])
        Group.fromJson(g as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(List<Group> groups) async {
    final file = await _file();
    final json = const JsonEncoder.withIndent('  ').convert({
      'version': _version,
      'groups': [for (final g in groups) g.toJson()],
    });
    // Write to a temp file first so a crash mid-write never corrupts the data.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(json, flush: true);
    await tmp.rename(file.path);
  }
}
