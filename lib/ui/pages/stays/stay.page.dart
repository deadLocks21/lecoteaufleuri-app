import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_detail.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/admin/stay_error_message.dart';
import 'package:lecoteaufleuri/ui/pages/stays/staff_picker.page.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

/// Un séjour et sa direction, pour l'admin, son directeur et ses adjoints.
///
/// Les boutons suivent ce que l'API dit permettre au compte connecté :
/// l'admin nomme ou retire le directeur, l'admin et le directeur nomment ou
/// retirent les adjoints. L'API revérifie chaque action.
class StayPage extends ConsumerWidget {
  final String stayId;

  /// Le nom déjà connu (liste d'où l'on vient), affiché pendant le chargement.
  final String? name;

  const StayPage({super.key, required this.stayId, this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(stayDetailControllerProvider(stayId));
    final value = detail.value;

    return Scaffold(
      appBar: AppBar(title: Text(value?.stay.name ?? name ?? 'Séjour')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: switch ((value, detail.error)) {
            (final StayDetailDto detail, _) => _StayView(
              stayId: stayId,
              detail: detail,
            ),
            (_, final Object error) => _ErrorView(
              message: stayErrorMessage(
                error is StayException ? error.code : StayErrorCode.unknown,
              ),
              onRetry: () =>
                  ref.invalidate(stayDetailControllerProvider(stayId)),
            ),
            _ => const CircularProgressIndicator(),
          },
        ),
      ),
    );
  }
}

class _StayView extends ConsumerWidget {
  final String stayId;
  final StayDetailDto detail;

  const _StayView({required this.stayId, required this.detail});

  Future<void> _name(BuildContext context, StaffRole role) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => StaffPickerPage(stayId: stayId, role: role),
      ),
    );
    if (message != null && context.mounted) _tell(context, message);
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    StaffRole role,
    TeamMemberDto member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          role == StaffRole.director
              ? 'Retirer le directeur ?'
              : 'Retirer cet adjoint ?',
        ),
        content: Text(
          '${member.fullName} ne fera plus partie de la direction de '
          '« ${detail.stay.name} ».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('confirmButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await ref
        .read(stayDetailControllerProvider(stayId).notifier)
        .remove(role, accountId: member.id);
    if (!context.mounted) return;
    _tell(
      context,
      error != null
          ? stayErrorMessage(error)
          : role == StaffRole.director
          ? 'Directeur retiré.'
          : 'Adjoint retiré.',
    );
  }

  /// Un message remplace le précédent au lieu d'attendre qu'il disparaisse.
  static void _tell(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stay = detail.stay;
    final director = detail.director;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          displayStayDates(stay.startsOn, stay.endsOn),
          key: const Key('stayDates'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '${stayKindLabel(stay.kind)} · ${stayKindDescription(stay.kind)}',
          style: muted,
        ),
        const SizedBox(height: 24),
        if (stay.kind != StayKind.acm)
          Text(
            'Séjour hors ACM : il n\'a ni directeur ni adjoint.',
            key: const Key('noDirection'),
            style: muted,
          )
        else ...[
          Text('Directeur', style: theme.textTheme.titleSmall),
          ListTile(
            key: const Key('directorTile'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(director?.fullName ?? 'Aucun directeur'),
            trailing: detail.canManageDirector
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const Key('nameDirectorButton'),
                        tooltip: director == null
                            ? 'Nommer le directeur'
                            : 'Changer de directeur',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _name(context, StaffRole.director),
                      ),
                      if (director != null)
                        IconButton(
                          key: const Key('removeDirectorButton'),
                          tooltip: 'Retirer le directeur',
                          icon: const Icon(Icons.person_remove_outlined),
                          onPressed: () => _remove(
                            context,
                            ref,
                            StaffRole.director,
                            director,
                          ),
                        ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text('Adjoints', style: theme.textTheme.titleSmall),
          if (detail.deputies.isEmpty)
            ListTile(
              key: const Key('noDeputies'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text('Aucun adjoint', style: muted),
            ),
          for (final deputy in detail.deputies)
            ListTile(
              key: Key('deputy-${deputy.id}'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(deputy.fullName),
              trailing: detail.canManageDeputies
                  ? IconButton(
                      key: Key('removeDeputy-${deputy.id}'),
                      tooltip: 'Retirer cet adjoint',
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () =>
                          _remove(context, ref, StaffRole.deputy, deputy),
                    )
                  : null,
            ),
          if (detail.canManageDeputies)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('addDeputyButton'),
                onPressed: () => _name(context, StaffRole.deputy),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Ajouter un adjoint'),
              ),
            ),
        ],
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            key: const Key('stayError'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
