import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/expense_sort.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/expense_tile.dart';
import '../widgets/groupay_app_bar.dart';
import '../widgets/settlement_card.dart';
import 'add_expense_screen.dart';
import 'members_sheet.dart';

const _sortLabels = {
  ExpenseSortField.date: 'תאריך',
  ExpenseSortField.amount: 'סכום',
  ExpenseSortField.category: 'קטגוריה',
  ExpenseSortField.payer: 'מי שילם',
};

/// Group screen: who owes whom at the top, the expenses below.
class GroupScreen extends StatefulWidget {
  final String groupId;

  const GroupScreen({super.key, required this.groupId});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  // Display-only sort; the stored expenses stay newest-first.
  ExpenseSortField _sortField = ExpenseSortField.date;
  bool _ascending = false;

  String get groupId => widget.groupId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final group = appState.groupById(groupId);
    if (group == null) return const Scaffold(appBar: GroupayAppBar());
    final hasMembers = group.members.isNotEmpty;
    final expenses = sortExpenses(
      group,
      field: _sortField,
      ascending: _ascending,
      categories: appState.categories,
    );

    return Scaffold(
      appBar: GroupayAppBar(
        subtitle: group.name,
        actions: [
          IconButton(
            tooltip: 'משתתפים',
            onPressed: () => showMembersSheet(context, groupId),
            icon: Badge.count(
              count: group.members.length,
              isLabelVisible: hasMembers,
              backgroundColor: GroupayColors.turquoise,
              child: const Icon(Icons.people_outline),
            ),
          ),
        ],
      ),
      floatingActionButton: hasMembers
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddExpenseScreen(groupId: groupId)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('הוצאה חדשה'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          SettlementCard(
            group: group,
            onAddMembers: () => showMembersSheet(context, groupId),
          ),
          if (hasMembers) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'הוצאות (${group.expenses.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (group.expenses.isNotEmpty) ...[
                    PopupMenuButton<ExpenseSortField>(
                      tooltip: 'מיון',
                      initialValue: _sortField,
                      // New field: date starts newest-first, the others ascending.
                      onSelected: (field) => setState(() {
                        _sortField = field;
                        _ascending = field != ExpenseSortField.date;
                      }),
                      itemBuilder: (_) => [
                        for (final MapEntry(:key, :value) in _sortLabels.entries)
                          CheckedPopupMenuItem(
                            value: key,
                            checked: key == _sortField,
                            child: Text(value),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sort, size: 20, color: GroupayColors.deepTeal),
                            const SizedBox(width: 4),
                            Text(
                              _sortLabels[_sortField]!,
                              style: const TextStyle(color: GroupayColors.deepTeal),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _ascending ? 'סדר עולה' : 'סדר יורד',
                      onPressed: () => setState(() => _ascending = !_ascending),
                      icon: Icon(
                        _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 20,
                        color: GroupayColors.deepTeal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (group.expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'לחצו על "הוצאה חדשה" כדי להוסיף את ההוצאה הראשונה',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              for (final e in expenses) ExpenseTile(group: group, expense: e),
          ],
        ],
      ),
    );
  }
}
