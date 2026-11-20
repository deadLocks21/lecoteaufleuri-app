import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lecoteaufleuri/ui/router/app_routes.dart';
import 'package:lecoteaufleuri/ui/shell/app_shell.dart';
import 'package:lecoteaufleuri/ui/widgets/space_card.widget.dart';

/// L'entrée de l'administration, réservée aux admins (le routeur en écarte
/// les autres) : les séjours et les comptes de toute l'association.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: shellMenuButton(context),
        automaticallyImplyLeading: false,
        title: const Text('Administration'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Toute l\'association',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SpaceCard(
                key: const Key('staysSpace'),
                icon: Icons.cabin_outlined,
                title: 'Séjours',
                subtitle: 'Créer un séjour, voir ceux de l\'association',
                onTap: () => context.go(AppRoutes.adminStays),
              ),
              SpaceCard(
                key: const Key('accountsSpace'),
                icon: Icons.manage_accounts_outlined,
                title: 'Comptes',
                subtitle:
                    'Créer, corriger ou supprimer un compte, nommer les admins',
                onTap: () => context.go(AppRoutes.adminAccounts),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
