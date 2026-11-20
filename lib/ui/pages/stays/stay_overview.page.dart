import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/infrastructure/providers/my_stays.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_space.provider.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay_modules.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay_space_view.dart';
import 'package:lecoteaufleuri/ui/router/app_routes.dart';
import 'package:lecoteaufleuri/ui/shell/app_shell.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

/// La vue d'ensemble d'un séjour : ses dates, le rôle qu'y tient le compte,
/// et une tuile par module auquel il a droit. Sur téléphone, c'est d'ici
/// qu'on ouvre les modules ; ailleurs, le rail les montre aussi.
class StayOverviewPage extends ConsumerWidget {
  final String stayId;

  const StayOverviewPage({super.key, required this.stayId});

  /// Tirer vers le bas relit les droits du compte et le séjour.
  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(myStaysProvider);
    ref.invalidate(staySpaceProvider(stayId));
    await ref.read(sessionControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(staySpaceProvider(stayId)).value?.stay.name;
    final state = ref.watch(sessionControllerProvider);
    final isAdmin = state is Authenticated && state.session.user.isAdmin;

    return Scaffold(
      appBar: AppBar(
        leading: shellMenuButton(context),
        automaticallyImplyLeading: false,
        title: Text(name ?? 'Séjour'),
      ),
      body: StaySpaceView(
        stayId: stayId,
        builder: (context, space) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: _Overview(space: space, isAdmin: isAdmin),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final StaySpaceDto space;
  final bool isAdmin;

  const _Overview({required this.space, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stay = space.stay;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final role = space.role == null
        ? 'Administration'
        : staffRoleLabel(space.role!);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              displayStayDates(stay.startsOn, stay.endsOn),
              key: const Key('stayDates'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('${stayKindLabel(stay.kind)} · $role', style: muted),
            if (stay.kind != StayKind.acm && isAdmin) ...[
              const SizedBox(height: 4),
              Text(
                'Séjour hors ACM : il n\'a ni direction ni animateurs.',
                key: const Key('noDirection'),
                style: muted,
              ),
            ],
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 12.0;
                // Deux tuiles par ligne sur téléphone, trois au plus.
                final columns = (constraints.maxWidth / 220).floor().clamp(
                  2,
                  3,
                );
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final module in StayModule.openTo(
                      space,
                      isAdmin: isAdmin,
                    ))
                      SizedBox(
                        width: width,
                        child: _ModuleTile(
                          module: module,
                          summary: module.summary(space, isAdmin: isAdmin),
                          onTap: () =>
                              context.go(AppRoutes.stayModule(stay.id, module)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// La tuile d'un module : son icône, son nom, ce qu'on y fait.
class _ModuleTile extends StatelessWidget {
  final StayModule module;
  final String summary;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.module,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: Key('${module.name}Module'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(module.icon, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(module.label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                summary,
                style: theme.textTheme.bodySmall?.copyWith(
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
