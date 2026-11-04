// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'port_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bound by `shell/` (AD-21). Throws until overridden.

@ProviderFor(payerUsagePort)
final payerUsagePortProvider = PayerUsagePortProvider._();

/// Bound by `shell/` (AD-21). Throws until overridden.

final class PayerUsagePortProvider
    extends $FunctionalProvider<PayerUsagePort, PayerUsagePort, PayerUsagePort>
    with $Provider<PayerUsagePort> {
  /// Bound by `shell/` (AD-21). Throws until overridden.
  PayerUsagePortProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'payerUsagePortProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$payerUsagePortHash();

  @$internal
  @override
  $ProviderElement<PayerUsagePort> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PayerUsagePort create(Ref ref) {
    return payerUsagePort(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PayerUsagePort value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PayerUsagePort>(value),
    );
  }
}

String _$payerUsagePortHash() => r'd9c046c58d260671b69cdfb615c17b7bcd18c512';

/// Bound by `shell/` (AD-21). Throws until overridden.

@ProviderFor(groupTotalsPort)
final groupTotalsPortProvider = GroupTotalsPortProvider._();

/// Bound by `shell/` (AD-21). Throws until overridden.

final class GroupTotalsPortProvider
    extends
        $FunctionalProvider<GroupTotalsPort, GroupTotalsPort, GroupTotalsPort>
    with $Provider<GroupTotalsPort> {
  /// Bound by `shell/` (AD-21). Throws until overridden.
  GroupTotalsPortProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupTotalsPortProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupTotalsPortHash();

  @$internal
  @override
  $ProviderElement<GroupTotalsPort> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GroupTotalsPort create(Ref ref) {
    return groupTotalsPort(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupTotalsPort value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupTotalsPort>(value),
    );
  }
}

String _$groupTotalsPortHash() => r'91dc906c7c8c2d07c7c46e10e2fad1fadbf8f437';
