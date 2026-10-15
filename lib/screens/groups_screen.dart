import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/groupay_app_bar.dart';
import '../widgets/groupay_logo.dart';
import 'group_screen.dart';

/// Home screen: the list of groups.
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final groups = state.groups;

    return Scaffold(
      appBar: const GroupayAppBar(),
      floatingActionButton: groups.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _createGroup(context),
              icon: const Icon(Icons.group_add),
              label: const Text('קבוצה חדשה'),
            ),
      body: !state.loaded
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
              ? _EmptyState(onCreate: () => _createGroup(context))
              : ListView(
                  padding: const EdgeInsets.only(top: 16, bottom: 96),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        'הקבוצות שלי',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    for (final group in groups) _GroupCard(group: group),
                  ],
                ),
    );
  }

  Future<void> _createGroup(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewGroupDialog(),
    );
    if (name == null || !context.mounted) return;
    await context.read<AppState>().addGroup(name);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GroupayLogo(size: 120),
            const SizedBox(height: 24),
            Text(
              'עוד אין קבוצות',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'פתחו קבוצה לטיול או לארוחה המשותפת הבאה,\nו-GrouPay יחשב מי חייב למי.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.group_add),
              label: const Text('פתח קבוצה ראשונה'),
              style: FilledButton.styleFrom(
                backgroundColor: GroupayColors.turquoise,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;

  const _GroupCard({required this.group});

  String get _membersLabel => switch (group.members.length) {
        0 => 'אין משתתפים עדיין',
        1 => 'משתתף אחד',
        final n => '$n משתתפים',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: NameAvatar(name: group.name),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        subtitle: Text(_membersLabel),
        trailing: Text(
          formatShekels(group.totalAgorot),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: GroupayColors.deepTeal,
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GroupScreen(groupId: group.id)),
        ),
        onLongPress: () => _confirmDelete(context),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת קבוצה'),
        content: Text('למחוק את הקבוצה "${group.name}" וכל ההוצאות שלה?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AppState>().deleteGroup(group.id);
    }
  }
}

class _NewGroupDialog extends StatefulWidget {
  const _NewGroupDialog();

  @override
  State<_NewGroupDialog> createState() => _NewGroupDialogState();
}

class _NewGroupDialogState extends State<_NewGroupDialog> {
  final _controller = TextEditingController();

  bool get _valid => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_valid) Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('קבוצה חדשה'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'שם הקבוצה',
          hintText: 'למשל: טיול צפון',
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        FilledButton(
          onPressed: _valid ? _submit : null,
          child: const Text('צור'),
        ),
      ],
    );
  }
}
