import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/widgets/empty_state.dart';

/// Placeholder of the "Together" tab until the session screens land.
class TogetherPage extends StatelessWidget {
  const TogetherPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTogether)),
      body: EmptyState(
        icon: Icons.group_outlined,
        title: l10n.togetherSoonTitle,
        message: l10n.togetherSoonMessage,
      ),
    );
  }
}
