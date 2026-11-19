import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/infrastructure/providers/my_stays.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/admin/accounts.page.dart';
import 'package:lecoteaufleuri/ui/pages/admin/stays.page.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay.page.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

/// Accueil, réservé aux comptes connectés (cf. `AuthGate`).
///
/// Il montre un espace par lien du compte avec l'association, et non un écran
/// par rôle : une même personne peut être admin, parent et animatrice. Pour
/// l'instant : « Mes séjours » (ceux que le compte dirige ou seconde) et
/// l'administration (séjours et comptes) ; les enfants viendront avec leurs
/// liens. Ce que l'accueil n'affiche pas reste de toute façon refusé par l'API.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Tirer vers le bas relit les droits du compte et ses séjours.
  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(myStaysProvider);
    await ref.read(sessionControllerProvider.notifier).refresh();
  }

  void _openStay(BuildContext context, MyStayDto mine) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StayPage(stayId: mine.stay.id, name: mine.stay.name),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    final user = state is Authenticated ? state.session.user : null;
    final isAdmin = user?.isAdmin ?? false;
    final myStays = ref.watch(myStaysProvider);
    final mine = myStays.value ?? const <MyStayDto>[];
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

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
          child: RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView(
              // Tirable même quand l'accueil tient dans l'écran.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Bonjour ${user?.firstName ?? ''} !',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                if (mine.isNotEmpty) ...[
                  Text('Mes séjours', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (final stay in mine)
                    _SpaceCard(
                      key: Key('myStay-${stay.stay.id}'),
                      icon: switch (stay.role) {
                        StaffRole.director => Icons.workspace_premium_outlined,
                        StaffRole.deputy => Icons.supervisor_account_outlined,
                      },
                      title: stay.stay.name,
                      subtitle:
                          '${staffRoleLabel(stay.role)} · '
                          '${displayStayDates(stay.stay.startsOn, stay.stay.endsOn)}',
                      onTap: () => _openStay(context, stay),
                    ),
                  const SizedBox(height: 24),
                ],
                if (myStays.hasError && !myStays.isLoading) ...[
                  Text(
                    'Vos séjours n\'ont pas pu être chargés. Tirez vers le bas '
                    'pour réessayer.',
                    key: const Key('myStaysError'),
                    style: muted,
                  ),
                  const SizedBox(height: 24),
                ],
                if (isAdmin) ...[
                  Text('Administration', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _SpaceCard(
                    key: const Key('staysSpace'),
                    icon: Icons.cabin_outlined,
                    title: 'Séjours',
                    subtitle: 'Créer un séjour, voir ceux de l\'association',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const StaysPage(),
                      ),
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
                ] else if (myStays.hasValue && mine.isEmpty)
                  Text(
                    'Rien à afficher pour l\'instant : vos séjours '
                    'apparaîtront ici.',
                    key: const Key('emptyHome'),
                    style: muted,
                  ),
              ],
            ),
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
