import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';

Future<void> showMembersSheet(BuildContext context, String groupId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MembersSheet(groupId: groupId),
  );
}

class _MembersSheet extends StatefulWidget {
  final String groupId;

  const _MembersSheet({required this.groupId});

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final added = await context.read<AppState>().addMember(widget.groupId, name);
    setState(() => _error = added ? null : 'השם "$name" כבר קיים בקבוצה');
    if (added) _controller.clear();
    _focus.requestFocus();
  }

  Future<void> _delete(String memberId, String name) async {
    final deleted = await context.read<AppState>().deleteMember(widget.groupId, memberId);
    if (deleted || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('לא ניתן למחוק'),
        content: Text('ל$name יש הוצאות בקבוצה. כדי למחוק אותו/ה, קודם מחקו את ההוצאות שלו/ה.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('הבנתי')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<AppState>().groupById(widget.groupId)!;
    final members = group.members;

    return Padding(
      // Keep the input above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'משתתפים (${members.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: members.isEmpty,
                      maxLength: 30,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'שם משתתף',
                        errorText: _error,
                        counterText: '',
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton.filled(
                      tooltip: 'הוסף',
                      onPressed: _add,
                      style: IconButton.styleFrom(backgroundColor: GroupayColors.turquoise),
                      icon: const Icon(Icons.person_add),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  for (final m in members)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      leading: NameAvatar(name: m.name, radius: 18),
                      title: Text(m.name),
                      trailing: IconButton(
                        tooltip: 'מחק',
                        icon: const Icon(Icons.close),
                        onPressed: () => _delete(m.id, m.name),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
