import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/expense_tile.dart';
import '../widgets/groupay_app_bar.dart';
import '../widgets/settlement_card.dart';
import 'add_expense_screen.dart';
import 'members_sheet.dart';

/// Group screen: who owes whom at the top, the expenses below.
class GroupScreen extends StatelessWidget {
  final String groupId;

  const GroupScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final group = context.watch<AppState>().groupById(groupId);
    if (group == null) return const Scaffold(appBar: GroupayAppBar());
    final hasMembers = group.members.isNotEmpty;

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'הוצאות (${group.expenses.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
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
              for (final e in group.expenses) ExpenseTile(group: group, expense: e),
          ],
        ],
      ),
    );
  }
}
