import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/json_storage.dart';
import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';

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

  /// Returns false (and changes nothing) if the name already exists in the group.
  Future<bool> addMember(String groupId, String name) async {
    final group = groupById(groupId)!;
    final trimmed = name.trim();
    if (group.members.any((m) => m.name == trimmed)) return false;
    final member = Member(id: _uuid.v4(), name: trimmed);
    await _updateGroup(group.copyWith(members: [...group.members, member]));
    return true;
  }

  /// Returns false (and changes nothing) if the member paid for any expense.
  Future<bool> deleteMember(String groupId, String memberId) async {
    final group = groupById(groupId)!;
    if (group.expenses.any((e) => e.payerId == memberId)) return false;
    await _updateGroup(group.copyWith(
      members: group.members.where((m) => m.id != memberId).toList(),
    ));
    return true;
  }

  Future<void> addExpense(
    String groupId, {
    required String payerId,
    required int amountAgorot,
    required String title,
    String details = '',
    List<String> participantIds = const [],
  }) async {
    final group = groupById(groupId)!;
    final expense = Expense(
      id: _uuid.v4(),
      payerId: payerId,
      amountAgorot: amountAgorot,
      title: title.trim(),
      details: details.trim(),
      createdAt: DateTime.now(),
      participantIds: participantIds,
    );
    // Newest expense first.
    await _updateGroup(group.copyWith(expenses: [expense, ...group.expenses]));
  }

  Future<void> deleteExpense(String groupId, String expenseId) async {
    final group = groupById(groupId)!;
    await _updateGroup(group.copyWith(
      expenses: group.expenses.where((e) => e.id != expenseId).toList(),
    ));
  }

  Future<void> _updateGroup(Group updated) async {
    _groups = [for (final g in _groups) g.id == updated.id ? updated : g];
    await _commit();
  }

  Future<void> _commit() async {
    notifyListeners();
    await _store.save(_groups);
  }
}
