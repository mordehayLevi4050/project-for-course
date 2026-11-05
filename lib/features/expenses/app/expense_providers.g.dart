// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bound by `shell/` (AD-21). Throws until overridden.

@ProviderFor(expenseRepository)
final expenseRepositoryProvider = ExpenseRepositoryProvider._();

/// Bound by `shell/` (AD-21). Throws until overridden.

final class ExpenseRepositoryProvider
    extends
        $FunctionalProvider<
          ExpenseRepository,
          ExpenseRepository,
          ExpenseRepository
        >
    with $Provider<ExpenseRepository> {
  /// Bound by `shell/` (AD-21). Throws until overridden.
  ExpenseRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExpenseRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExpenseRepository create(Ref ref) {
    return expenseRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExpenseRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExpenseRepository>(value),
    );
  }
}

String _$expenseRepositoryHash() => r'ad039f81144bfe1f125b4e12c676db2ba53f2ebe';

/// The Expenses of a Group, newest first by `saveSeq`.

@ProviderFor(expenses)
final expensesProvider = ExpensesFamily._();

/// The Expenses of a Group, newest first by `saveSeq`.

final class ExpensesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Expense>>,
          List<Expense>,
          Stream<List<Expense>>
        >
    with $FutureModifier<List<Expense>>, $StreamProvider<List<Expense>> {
  /// The Expenses of a Group, newest first by `saveSeq`.
  ExpensesProvider._({
    required ExpensesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'expensesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expensesHash();

  @override
  String toString() {
    return r'expensesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Expense>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Expense>> create(Ref ref) {
    final argument = this.argument as String;
    return expenses(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpensesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expensesHash() => r'de359e21b466f2489c1c3cce4711b0cb80df2f8a';

/// The Expenses of a Group, newest first by `saveSeq`.

final class ExpensesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Expense>>, String> {
  ExpensesFamily._()
    : super(
        retry: null,
        name: r'expensesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Expenses of a Group, newest first by `saveSeq`.

  ExpensesProvider call(String groupId) =>
      ExpensesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'expensesProvider';
}

/// One Expense, or `null` once it is deleted (Edit expense).

@ProviderFor(expense)
final expenseProvider = ExpenseFamily._();

/// One Expense, or `null` once it is deleted (Edit expense).

final class ExpenseProvider
    extends
        $FunctionalProvider<AsyncValue<Expense?>, Expense?, Stream<Expense?>>
    with $FutureModifier<Expense?>, $StreamProvider<Expense?> {
  /// One Expense, or `null` once it is deleted (Edit expense).
  ExpenseProvider._({
    required ExpenseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'expenseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expenseHash();

  @override
  String toString() {
    return r'expenseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Expense?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Expense?> create(Ref ref) {
    final argument = this.argument as String;
    return expense(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpenseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expenseHash() => r'812ebcaaaa84a159facae0484b51a06b8a48e50b';

/// One Expense, or `null` once it is deleted (Edit expense).

final class ExpenseFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Expense?>, String> {
  ExpenseFamily._()
    : super(
        retry: null,
        name: r'expenseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One Expense, or `null` once it is deleted (Edit expense).

  ExpenseProvider call(String id) =>
      ExpenseProvider._(argument: id, from: this);

  @override
  String toString() => r'expenseProvider';
}

/// The default Payer of a new Expense in [groupId] (FR-10): the Payer of the
/// last saved Expense, or the earliest-added Member. Read once when the Add
/// expense screen opens.

@ProviderFor(defaultPayerId)
final defaultPayerIdProvider = DefaultPayerIdFamily._();

/// The default Payer of a new Expense in [groupId] (FR-10): the Payer of the
/// last saved Expense, or the earliest-added Member. Read once when the Add
/// expense screen opens.

final class DefaultPayerIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// The default Payer of a new Expense in [groupId] (FR-10): the Payer of the
  /// last saved Expense, or the earliest-added Member. Read once when the Add
  /// expense screen opens.
  DefaultPayerIdProvider._({
    required DefaultPayerIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'defaultPayerIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$defaultPayerIdHash();

  @override
  String toString() {
    return r'defaultPayerIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return defaultPayerId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DefaultPayerIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$defaultPayerIdHash() => r'5e550e0be68ec9c5dcf22996ae6d1e47fe835eac';

/// The default Payer of a new Expense in [groupId] (FR-10): the Payer of the
/// last saved Expense, or the earliest-added Member. Read once when the Add
/// expense screen opens.

final class DefaultPayerIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  DefaultPayerIdFamily._()
    : super(
        retry: null,
        name: r'defaultPayerIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The default Payer of a new Expense in [groupId] (FR-10): the Payer of the
  /// last saved Expense, or the earliest-added Member. Read once when the Add
  /// expense screen opens.

  DefaultPayerIdProvider call(String groupId) =>
      DefaultPayerIdProvider._(argument: groupId, from: this);

  @override
  String toString() => r'defaultPayerIdProvider';
}

/// Records an Expense. The state is `true` while a save is in flight; calls
/// made meanwhile are ignored and return `null`.

@ProviderFor(AddExpense)
final addExpenseProvider = AddExpenseProvider._();

/// Records an Expense. The state is `true` while a save is in flight; calls
/// made meanwhile are ignored and return `null`.
final class AddExpenseProvider extends $NotifierProvider<AddExpense, bool> {
  /// Records an Expense. The state is `true` while a save is in flight; calls
  /// made meanwhile are ignored and return `null`.
  AddExpenseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addExpenseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addExpenseHash();

  @$internal
  @override
  AddExpense create() => AddExpense();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$addExpenseHash() => r'1d788e87473ffd64b93f780171e2e85432c5f1e4';

/// Records an Expense. The state is `true` while a save is in flight; calls
/// made meanwhile are ignored and return `null`.

abstract class _$AddExpense extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Edits an Expense (FR-13). The state is `true` while a save is in flight;
/// calls made meanwhile are ignored and return `null`.

@ProviderFor(EditExpense)
final editExpenseProvider = EditExpenseProvider._();

/// Edits an Expense (FR-13). The state is `true` while a save is in flight;
/// calls made meanwhile are ignored and return `null`.
final class EditExpenseProvider extends $NotifierProvider<EditExpense, bool> {
  /// Edits an Expense (FR-13). The state is `true` while a save is in flight;
  /// calls made meanwhile are ignored and return `null`.
  EditExpenseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editExpenseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editExpenseHash();

  @$internal
  @override
  EditExpense create() => EditExpense();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$editExpenseHash() => r'db3ed7a830e8f920605f8aadf0d9996c5d4d951b';

/// Edits an Expense (FR-13). The state is `true` while a save is in flight;
/// calls made meanwhile are ignored and return `null`.

abstract class _$EditExpense extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Deletes an Expense (FR-14), after the Delete sheet. The state is `true`
/// while the delete is in flight; calls made meanwhile are ignored and
/// return `null`.

@ProviderFor(DeleteExpense)
final deleteExpenseProvider = DeleteExpenseProvider._();

/// Deletes an Expense (FR-14), after the Delete sheet. The state is `true`
/// while the delete is in flight; calls made meanwhile are ignored and
/// return `null`.
final class DeleteExpenseProvider
    extends $NotifierProvider<DeleteExpense, bool> {
  /// Deletes an Expense (FR-14), after the Delete sheet. The state is `true`
  /// while the delete is in flight; calls made meanwhile are ignored and
  /// return `null`.
  DeleteExpenseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteExpenseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteExpenseHash();

  @$internal
  @override
  DeleteExpense create() => DeleteExpense();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$deleteExpenseHash() => r'8759b675089ec0383d5f0b0ca56f398e069bbc40';

/// Deletes an Expense (FR-14), after the Delete sheet. The state is `true`
/// while the delete is in flight; calls made meanwhile are ignored and
/// return `null`.

abstract class _$DeleteExpense extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
