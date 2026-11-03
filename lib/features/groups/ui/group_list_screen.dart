import 'package:flutter/material.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/app_scaffold.dart';

/// The home screen: the list of Groups (FR-1).
///
/// Story 1.1 part 1 shows only the empty state. Group cards and the create
/// flow arrive in part 2.
class GroupListScreen extends StatelessWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s3,
          AppSpacing.s5,
          AppSpacing.s6,
        ),
        child: Column(
          children: [
            Text(MessageKey.appName.text, style: AppTextStyles.screenTitle),
            Text(
              MessageKey.myGroups.text,
              style: AppTextStyles.headerSecondary,
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Text(
            MessageKey.emptyGroupList.text,
            textAlign: TextAlign.center,
            style: AppTextStyles.message.copyWith(color: AppColors.inkMuted),
          ),
        ),
      ),
      bottomBar: Row(
        children: [
          Expanded(
            flex: 2,
            child: FilledButton(
              // The create flow is Story 1.1 part 2.
              onPressed: () {},
              child: Text(MessageKey.newGroup.text),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
