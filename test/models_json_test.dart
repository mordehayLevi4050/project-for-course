import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/data/json_storage.dart';
import 'package:groupay/models/expense.dart';
import 'package:groupay/models/group.dart';
import 'package:groupay/models/member.dart';

void main() {
  final group = Group(
    id: 'g1',
    name: 'טיול צפון',
    createdAt: DateTime(2026, 10, 15, 12),
    members: const [Member(id: 'm1', name: 'דני'), Member(id: 'm2', name: 'רוני')],
    expenses: [
      Expense(
        id: 'e1',
        payerId: 'm1',
        amountAgorot: 30050,
        title: 'דלק',
        details: 'תדלוק בדרך לכנרת',
        createdAt: DateTime(2026, 10, 15, 13),
      ),
    ],
  );

  test('Group JSON round-trip keeps all fields', () {
    final copy = Group.fromJson(group.toJson());
    expect(copy.toJson(), group.toJson());
    expect(copy.totalAgorot, 30050);
  });

  test('JsonStorage saves and loads from disk', () async {
    final dir = await Directory.systemTemp.createTemp('groupay_test');
    addTearDown(() => dir.delete(recursive: true));
    final storage = JsonStorage(directory: () async => dir);

    expect(await storage.load(), isEmpty);
    expect(await storage.loadCategories(), isNull);
    await storage.save([group], const ['דלק', 'אחר']);
    final loaded = await storage.load();
    expect(loaded.single.toJson(), group.toJson());
    expect(await storage.loadCategories(), ['דלק', 'אחר']);
  });
}
