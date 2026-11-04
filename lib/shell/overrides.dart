import 'package:flutter_riverpod/misc.dart';

import '../core/db/app_database.dart';
import '../core/db/database_provider.dart';
import '../core/ports/payer_usage_port.dart';
import '../core/ports/port_providers.dart';
import '../core/time/clock.dart';
import '../core/time/clock_provider.dart';
import '../features/expenses/app/expense_providers.dart';
import '../features/expenses/data/drift_expense_repository.dart';
import '../features/expenses/data/drift_group_totals.dart';
import '../features/expenses/data/drift_payer_usage.dart';
import '../features/groups/app/repository_providers.dart';
import '../features/groups/data/drift_group_repository.dart';
import '../features/groups/data/drift_member_repository.dart';

/// Binds every interface provider to its implementation (AD-21). This is the
/// only place that knows the concrete classes.
///
/// Both ports are implemented in `expenses/data` and depend only on the
/// database, which keeps the provider graph acyclic. [payerUsage] replaces
/// the drift `PayerUsagePort` (tests only).
List<Override> appOverrides({
  required AppDatabase database,
  Clock clock = const SystemClock(),
  PayerUsagePort? payerUsage,
}) => [
  appDatabaseProvider.overrideWithValue(database),
  clockProvider.overrideWithValue(clock),
  payerUsage == null
      ? payerUsagePortProvider.overrideWith(
          (ref) => DriftPayerUsage(ref.watch(appDatabaseProvider)),
        )
      : payerUsagePortProvider.overrideWithValue(payerUsage),
  groupTotalsPortProvider.overrideWith(
    (ref) => DriftGroupTotals(ref.watch(appDatabaseProvider)),
  ),
  groupRepositoryProvider.overrideWith(
    (ref) => DriftGroupRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(clockProvider),
    ),
  ),
  memberRepositoryProvider.overrideWith(
    (ref) => DriftMemberRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(clockProvider),
      ref.watch(payerUsagePortProvider),
    ),
  ),
  expenseRepositoryProvider.overrideWith(
    (ref) => DriftExpenseRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(clockProvider),
    ),
  ),
];
