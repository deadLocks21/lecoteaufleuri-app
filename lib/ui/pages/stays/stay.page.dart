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
/// l'admin nomme ou retire les directeurs, l'admin et les directeurs nomment
/// ou retirent les adjoints. L'API revérifie chaque action.
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
              ? 'Retirer ce directeur ?'
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

  /// Les directeurs ou les adjoints : un titre, chaque membre (retirable si
  /// [canManage]) et de quoi en nommer un autre.
  List<Widget> _section(
    BuildContext context,
    WidgetRef ref, {
    required StaffRole role,
    required String title,
    required List<TeamMemberDto> members,
    required bool canManage,
  }) {
    final theme = Theme.of(context);
    final director = role == StaffRole.director;
    final name = director ? 'director' : 'deputy';
    return [
      Text(title, style: theme.textTheme.titleSmall),
      if (members.isEmpty)
        ListTile(
          key: Key(director ? 'noDirectors' : 'noDeputies'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline),
          title: Text(
            director ? 'Aucun directeur' : 'Aucun adjoint',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      for (final member in members)
        ListTile(
          key: Key('$name-${member.id}'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            director ? Icons.workspace_premium_outlined : Icons.person_outline,
          ),
          title: Text(member.fullName),
          trailing: canManage
              ? IconButton(
                  key: Key(
                    '${director ? 'removeDirector' : 'removeDeputy'}-'
                    '${member.id}',
                  ),
                  tooltip: director
                      ? 'Retirer ce directeur'
                      : 'Retirer cet adjoint',
                  icon: const Icon(Icons.person_remove_outlined),
                  onPressed: () => _remove(context, ref, role, member),
                )
              : null,
        ),
      if (canManage)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: Key(director ? 'addDirectorButton' : 'addDeputyButton'),
            onPressed: () => _name(context, role),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(
              director ? 'Ajouter un directeur' : 'Ajouter un adjoint',
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stay = detail.stay;
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
          ..._section(
            context,
            ref,
            role: StaffRole.director,
            title: 'Directeurs',
            members: detail.directors,
            canManage: detail.canManageDirectors,
          ),
          const SizedBox(height: 16),
          ..._section(
            context,
            ref,
            role: StaffRole.deputy,
            title: 'Adjoints',
            members: detail.deputies,
            canManage: detail.canManageDeputies,
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
