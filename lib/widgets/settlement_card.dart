import 'package:flutter/material.dart';

import '../logic/money.dart';
import '../logic/settlement.dart';
import '../models/group.dart';
import '../theme.dart';
import 'avatar.dart';

/// Top-of-page summary: totals, who pays whom, and each member's balance.
class SettlementCard extends StatelessWidget {
  final Group group;
  final VoidCallback onAddMembers;

  const SettlementCard({super.key, required this.group, required this.onAddMembers});

  @override
  Widget build(BuildContext context) {
    final settlement = Settlement.of(group);
    final members = group.members;
    final perPerson = members.isEmpty ? 0 : settlement.totalAgorot ~/ members.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [GroupayColors.turquoise, GroupayColors.deepTeal],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Totals.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: _Figure(label: 'סה״כ הוצאות', value: formatShekels(settlement.totalAgorot)),
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                Expanded(
                  child: _Figure(label: 'לכל אחד', value: formatShekels(perPerson)),
                ),
              ],
            ),
          ),
          // Who owes whom.
          Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: members.isEmpty
                ? _NoMembers(onAddMembers: onAddMembers)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'מי חייב למי',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (settlement.totalAgorot == 0)
                        const _Note(icon: Icons.receipt_long, text: 'עוד אין הוצאות בקבוצה')
                      else if (settlement.transfers.isEmpty)
                        const _Note(icon: Icons.check_circle, text: 'כולם מאוזנים, אין חובות')
                      else
                        for (final t in settlement.transfers)
                          _TransferRow(group: group, transfer: t),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in members)
                            _BalanceChip(name: m.name, balance: settlement.balances[m.id]!),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;

  const _Figure({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TransferRow extends StatelessWidget {
  final Group group;
  final Transfer transfer;

  const _TransferRow({required this.group, required this.transfer});

  @override
  Widget build(BuildContext context) {
    final from = group.memberById(transfer.fromId)!.name;
    final to = group.memberById(transfer.toId)!.name;
    const nameStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    // Reads right to left: payer -> amount -> receiver.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          NameAvatar(name: from, radius: 16),
          const SizedBox(width: 8),
          Flexible(child: Text(from, style: nameStyle, overflow: TextOverflow.ellipsis)),
          Expanded(
            child: Column(
              children: [
                Text(
                  formatShekels(transfer.amountAgorot),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: GroupayColors.deepTeal,
                  ),
                ),
                // arrow_forward is mirrored in RTL, so it points from payer to receiver.
                const Icon(Icons.arrow_forward, size: 18, color: GroupayColors.turquoise),
              ],
            ),
          ),
          Flexible(child: Text(to, style: nameStyle, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          NameAvatar(name: to, radius: 16),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  final String name;
  final int balance;

  const _BalanceChip({required this.name, required this.balance});

  @override
  Widget build(BuildContext context) {
    final color = balance > 0
        ? GroupayColors.positive
        : balance < 0
            ? GroupayColors.negative
            : Colors.black54;
    final status = balance > 0
        ? 'מקבל/ת ${formatShekels(balance)}'
        : balance < 0
            ? 'חייב/ת ${formatShekels(-balance)}'
            : 'מאוזן/ת';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Note({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: GroupayColors.turquoise),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

class _NoMembers extends StatelessWidget {
  final VoidCallback onAddMembers;

  const _NoMembers({required this.onAddMembers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'הוסיפו את המשתתפים בטיול כדי להתחיל',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onAddMembers,
          icon: const Icon(Icons.person_add),
          label: const Text('הוספת משתתפים'),
        ),
      ],
    );
  }
}
