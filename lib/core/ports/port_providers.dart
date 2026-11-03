import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'payer_usage_port.dart';

part 'port_providers.g.dart';

/// Bound by `shell/` (AD-21). Throws until overridden.
@Riverpod(keepAlive: true)
PayerUsagePort payerUsagePort(Ref ref) =>
    throw UnimplementedError('payerUsagePortProvider is bound in shell/');
