import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/groupay_app_bar.dart';

/// Group screen. Placeholder for now; the settlement summary and expenses
/// list are built in the next stage.
class GroupScreen extends StatelessWidget {
  final String groupId;

  const GroupScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final group = context.watch<AppState>().groupById(groupId);

    return Scaffold(
      appBar: GroupayAppBar(subtitle: group?.name),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 56, color: Colors.black38),
              const SizedBox(height: 16),
              Text(
                'כאן יופיע הסיכום של מי חייב למי\nורשימת ההוצאות של הקבוצה',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
