import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../logic/money.dart';
import '../models/expense.dart';
import '../models/group.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'avatar.dart';

final _dateFormat = DateFormat('d.M.yyyy · HH:mm');

class ExpenseTile extends StatelessWidget {
  final Group group;
  final Expense expense;

  const ExpenseTile({super.key, required this.group, required this.expense});

  @override
  Widget build(BuildContext context) {
    final payer = group.memberById(expense.payerId)?.name ?? '?';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: NameAvatar(name: payer),
        title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('שילם/ה: $payer'),
        trailing: Text(
          formatShekels(expense.amountAgorot),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: GroupayColors.deepTeal,
          ),
        ),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => _ExpenseDetails(group: group, expense: expense, payer: payer),
        ),
      ),
    );
  }
}

class _ExpenseDetails extends StatelessWidget {
  final Group group;
  final Expense expense;
  final String payer;

  const _ExpenseDetails({required this.group, required this.expense, required this.payer});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              formatShekels(expense.amountAgorot),
              textAlign: TextAlign.center,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: GroupayColors.deepTeal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              expense.title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                NameAvatar(name: payer, radius: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('שילם/ה: $payer', style: textTheme.bodyLarge)),
                Text(
                  _dateFormat.format(expense.createdAt),
                  style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GroupayColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                expense.details.isEmpty ? 'אין פירוט להוצאה הזו' : expense.details,
                style: textTheme.bodyLarge?.copyWith(
                  color: expense.details.isEmpty ? Colors.black45 : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _delete(context),
              style: TextButton.styleFrom(foregroundColor: GroupayColors.negative),
              icon: const Icon(Icons.delete_outline),
              label: const Text('מחיקת ההוצאה'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת הוצאה'),
        content: Text('למחוק את ההוצאה "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: GroupayColors.negative),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AppState>().deleteExpense(group.id, expense.id);
    if (context.mounted) Navigator.pop(context);
  }
}
