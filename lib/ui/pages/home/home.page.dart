import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/admin/accounts.page.dart';
import 'package:lecoteaufleuri/ui/pages/admin/stays.page.dart';

/// Accueil, réservé aux comptes connectés (cf. `AuthGate`).
///
/// Il montre un espace par lien du compte avec l'association, et non un écran
/// par rôle : une même personne peut être admin, parent et animatrice. Pour
/// l'instant, seul l'espace d'administration existe (séjours et comptes) ;
/// les séjours encadrés et les enfants viendront avec leurs liens. Ce que
/// l'accueil n'affiche pas reste de toute façon refusé par l'API.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    final user = state is Authenticated ? state.session.user : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Le Coteau Fleuri'),
        actions: [
          IconButton(
            key: const Key('logoutButton'),
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Bonjour ${user?.firstName ?? ''} !',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              if (user?.isAdmin ?? false) ...[
                Text('Administration', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _SpaceCard(
                  key: const Key('staysSpace'),
                  icon: Icons.cabin_outlined,
                  title: 'Séjours',
                  subtitle: 'Créer un séjour, voir ceux de l\'association',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const StaysPage()),
                  ),
                ),
                _SpaceCard(
                  key: const Key('accountsSpace'),
                  icon: Icons.manage_accounts_outlined,
                  title: 'Comptes',
                  subtitle:
                      'Créer, corriger ou supprimer un compte, nommer les admins',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountsPage(),
                    ),
                  ),
                ),
              ] else
                Text(
                  'Rien à afficher pour l\'instant : vos séjours '
                  'apparaîtront ici.',
                  key: const Key('emptyHome'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SpaceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
