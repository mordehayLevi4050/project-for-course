import 'package:flutter_riverpod/misc.dart';

import '../core/db/app_database.dart';
import '../core/db/database_provider.dart';
import '../core/ports/port_providers.dart';
import '../core/time/clock.dart';
import '../core/time/clock_provider.dart';
import '../features/groups/app/repository_providers.dart';
import '../features/groups/data/drift_group_repository.dart';
import '../features/groups/data/drift_member_repository.dart';
import 'payer_usage_stand_in.dart';

/// Binds every interface provider to its implementation (AD-21). This is the
/// only place that knows the concrete classes.
List<Override> appOverrides({
  required AppDatabase database,
  Clock clock = const SystemClock(),
}) => [
  appDatabaseProvider.overrideWithValue(database),
  clockProvider.overrideWithValue(clock),
  payerUsagePortProvider.overrideWithValue(const NoPayerUsage()),
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
    ),
  ),
];
