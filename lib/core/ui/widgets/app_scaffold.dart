import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// The page frame every screen uses (AD-22).
///
/// Android 15 draws edge to edge: the optional [header] sits on the lagoon
/// gradient, which runs under the status bar, while its content is kept below
/// it. The [body] resizes for the keyboard. The optional [bottomBar] holds the
/// primary actions in the thumb zone, above the navigation bar.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.header,
    required this.body,
    this.bottomBar,
  });

  final Widget? header;
  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final bottomBar = this.bottomBar;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: header != null
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surfaceBase,
        resizeToAvoidBottomInset: true,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null)
              DecoratedBox(
                decoration: const BoxDecoration(gradient: AppGradients.header),
                child: SafeArea(
                  bottom: false,
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: AppColors.onHeader),
                    child: header,
                  ),
                ),
              ),
            Expanded(
              child: SafeArea(
                top: header == null,
                bottom: bottomBar == null,
                child: body,
              ),
            ),
            if (bottomBar != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.marginMobile,
                    AppSpacing.s2,
                    AppSpacing.marginMobile,
                    AppSpacing.s4,
                  ),
                  child: bottomBar,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
