import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/money/tenths.dart';
import '../../../core/ports/group_totals_port.dart';

/// The drift [GroupTotalsPort] (AD-2): each Group's Trip total, for the
/// group cards. Depends only on [AppDatabase].
final class DriftGroupTotals implements GroupTotalsPort {
  DriftGroupTotals(this._db);

  final AppDatabase _db;

  @override
  Stream<Map<String, Tenths>> watchTotals() {
    final total = _db.expenses.amount.sum();
    final query = _db.selectOnly(_db.expenses)
      ..addColumns([_db.expenses.groupId, total])
      ..groupBy([_db.expenses.groupId]);
    return query.watch().map(
      (rows) => {
        for (final row in rows)
          row.read(_db.expenses.groupId)!: Tenths(row.read(total) ?? 0),
      },
    );
  }
}
