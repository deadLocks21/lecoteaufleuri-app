import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/infrastructure/providers/my_stays.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stays.service_provider.dart';
import 'package:lecoteaufleuri/ui/router/app_routes.dart';

/// L'entrée de l'app connectée : elle ouvre le séjour du moment (cf.
/// `defaultStay`), ou l'administration pour un admin sans séjour. Sans l'un
/// ni l'autre, elle le dit.
class StartPage extends ConsumerStatefulWidget {
  const StartPage({super.key});

  @override
  ConsumerState<StartPage> createState() => _StartPageState();
}

class _StartPageState extends ConsumerState<StartPage> {
  bool _opening = false;

  Future<void> _open(String accountId, List<MyStayDto> mine) async {
    if (_opening) return;
    _opening = true;
    final picked = await ref
        .read(staysServiceProvider)
        .pickDefault
        .execute(accountId, mine);
    if (!mounted) return;
    context.go(
      picked == null ? AppRoutes.admin : AppRoutes.stay(picked.stay.id),
    );
  }

  /// Tirer vers le bas relit les droits du compte et ses séjours.
  Future<void> _refresh() async {
    ref.invalidate(myStaysProvider);
    await ref.read(sessionControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider);
    final user = state is Authenticated ? state.session.user : null;
    final isAdmin = user?.isAdmin ?? false;
    final myStays = ref.watch(myStaysProvider);
    final mine = myStays.value;

    if (user != null && mine != null && (mine.isNotEmpty || isAdmin)) {
      _open(user.id, mine);
    } else if (user != null && isAdmin && myStays.hasError) {
      // Un admin a toujours un espace où aller : l'administration.
      _open(user.id, const []);
    }
    final opening = _opening || (mine == null && !myStays.hasError);
    if (opening) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            onRefresh: _refresh,
            child: ListView(
              // Tirable même quand la page tient dans l'écran.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Bonjour ${user?.firstName ?? ''} !',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                if (myStays.hasError)
                  Text(
                    'Vos séjours n\'ont pas pu être chargés. Tirez vers le bas '
                    'pour réessayer.',
                    key: const Key('myStaysError'),
                    style: muted,
                  )
                else
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
