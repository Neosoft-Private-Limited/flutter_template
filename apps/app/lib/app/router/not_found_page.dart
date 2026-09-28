import 'package:app/app/router/routes.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// Shown for unknown paths and rejected deep links.
class NotFoundPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notFoundTitle)),
      body: AppMessageView(
        icon: Icons.link_off,
        title: l10n.notFoundTitle,
        message: l10n.notFoundMessage,
        actionLabel: l10n.goHomeAction,
        onAction: () => context.go(AppRoutes.home),
      ),
    );
  }
}
