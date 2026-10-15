import 'package:flutter/material.dart';

import '../theme.dart';
import 'groupay_logo.dart';

/// The app bar shown on every screen: GrouPay logo + name, optional subtitle.
class GroupayAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? subtitle;
  final List<Widget>? actions;

  const GroupayAppBar({super.key, this.subtitle, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      toolbarHeight: kToolbarHeight + 8,
      titleSpacing: 8,
      actions: actions,
      title: Row(
        children: [
          const GroupayLogo(size: 36),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GrouPay',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: GroupayColors.deepTeal,
                    letterSpacing: 0.3,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
