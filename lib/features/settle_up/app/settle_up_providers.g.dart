// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settle_up_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Summary of [groupId] (FR-15, FR-16). It only reads: each snapshot
/// from `watchSnapshot` is checked with `maySummarize` and settled by the
/// pure calculation, again after every change to Members or Expenses.

@ProviderFor(settlement)
final settlementProvider = SettlementFamily._();

/// The Summary of [groupId] (FR-15, FR-16). It only reads: each snapshot
/// from `watchSnapshot` is checked with `maySummarize` and settled by the
/// pure calculation, again after every change to Members or Expenses.

final class SettlementProvider
    extends
        $FunctionalProvider<
          AsyncValue<SummaryView>,
          SummaryView,
          Stream<SummaryView>
        >
    with $FutureModifier<SummaryView>, $StreamProvider<SummaryView> {
  /// The Summary of [groupId] (FR-15, FR-16). It only reads: each snapshot
  /// from `watchSnapshot` is checked with `maySummarize` and settled by the
  /// pure calculation, again after every change to Members or Expenses.
  SettlementProvider._({
    required SettlementFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'settlementProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$settlementHash();

  @override
  String toString() {
    return r'settlementProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SummaryView> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SummaryView> create(Ref ref) {
    final argument = this.argument as String;
    return settlement(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SettlementProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$settlementHash() => r'64c3616c8d38773d09ebc4374bc2a961827d620a';

/// The Summary of [groupId] (FR-15, FR-16). It only reads: each snapshot
/// from `watchSnapshot` is checked with `maySummarize` and settled by the
/// pure calculation, again after every change to Members or Expenses.

final class SettlementFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SummaryView>, String> {
  SettlementFamily._()
    : super(
        retry: null,
        name: r'settlementProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Summary of [groupId] (FR-15, FR-16). It only reads: each snapshot
  /// from `watchSnapshot` is checked with `maySummarize` and settled by the
  /// pure calculation, again after every change to Members or Expenses.

  SettlementProvider call(String groupId) =>
      SettlementProvider._(argument: groupId, from: this);

  @override
  String toString() => r'settlementProvider';
}
