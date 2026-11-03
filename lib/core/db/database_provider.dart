import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';

part 'database_provider.g.dart';

/// The single [AppDatabase] instance (AD-6). `shell/` creates it and overrides
/// this provider; it throws until then.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) =>
    throw UnimplementedError('appDatabaseProvider is bound in shell/');
