import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'clock.dart';

part 'clock_provider.g.dart';

/// Bound by `shell/` (AD-21). Throws until overridden.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) =>
    throw UnimplementedError('clockProvider is bound in shell/');
