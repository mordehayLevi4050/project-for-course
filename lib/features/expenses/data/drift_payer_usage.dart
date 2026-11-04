import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/ports/payer_usage_port.dart';

/// The drift [PayerUsagePort] (FR-4, AD-2): whether a Member is the Payer of
/// any Expense. Depends only on [AppDatabase]. Called inside the remove
/// transaction of `groups`, so it reads the same snapshot.
final class DriftPayerUsage implements PayerUsagePort {
  DriftPayerUsage(this._db);

  final AppDatabase _db;

  @override
  Future<bool> isPayer(String groupId, String memberId) async {
    final row =
        await (_db.selectOnly(_db.expenses)
              ..addColumns([_db.expenses.id])
              ..where(
                _db.expenses.groupId.equals(groupId) &
                    _db.expenses.payerId.equals(memberId),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }
}
