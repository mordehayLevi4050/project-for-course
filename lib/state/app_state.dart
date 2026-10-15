import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/json_storage.dart';
import '../models/group.dart';

class AppState extends ChangeNotifier {
  final GroupStore _store;
  final _uuid = const Uuid();

  List<Group> _groups = [];
  bool _loaded = false;

  AppState(this._store);

  /// Newest group first.
  List<Group> get groups => List.unmodifiable(_groups);
  bool get loaded => _loaded;

  Group? groupById(String id) {
    for (final g in _groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  Future<void> load() async {
    _groups = await _store.load()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _loaded = true;
    notifyListeners();
  }

  Future<Group> addGroup(String name) async {
    final group = Group(
      id: _uuid.v4(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    _groups = [group, ..._groups];
    await _commit();
    return group;
  }

  Future<void> deleteGroup(String id) async {
    _groups = _groups.where((g) => g.id != id).toList();
    await _commit();
  }

  Future<void> _commit() async {
    notifyListeners();
    await _store.save(_groups);
  }
}
