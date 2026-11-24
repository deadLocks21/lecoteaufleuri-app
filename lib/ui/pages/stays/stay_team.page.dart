import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_detail.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/admin/stay_error_message.dart';
import 'package:lecoteaufleuri/ui/pages/stays/staff_picker.page.dart';
import 'package:lecoteaufleuri/ui/shell/app_shell.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

/// Le module Équipe d'un séjour : ses directeurs, ses adjoints et ses
/// animateurs, pour l'admin, ses directeurs et ses adjoints.
///
/// La page s'ouvre en lecture seule ; « Modifier », dans la barre du haut,
/// passe en mode édition, où l'on ajoute ou retire des membres, et
/// « Terminé » en revient. Le bouton n'apparaît que si le compte connecté
/// peut changer une partie de l'équipe.
///
/// En édition, les boutons suivent ce que l'API dit permettre au compte
/// connecté :
/// l'admin nomme ou retire les directeurs, l'admin et les directeurs nomment
/// ou retirent les adjoints, et tous trois ajoutent ou retirent les
/// animateurs. L'API revérifie chaque action.
class StayTeamPage extends ConsumerStatefulWidget {
  final String stayId;

  const StayTeamPage({super.key, required this.stayId});

  @override
  ConsumerState<StayTeamPage> createState() => _StayTeamPageState();
}

class _StayTeamPageState extends ConsumerState<StayTeamPage> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final stayId = widget.stayId;
    final detail = ref.watch(stayDetailControllerProvider(stayId));
    final value = detail.value;
    final canEdit =
        value != null &&
        value.stay.kind == StayKind.acm &&
        (value.canManageDirectors ||
            value.canManageDeputies ||
            value.canManageAnimators);
    // Des droits perdus en cours de route referment l'édition.
    final editing = _editing && canEdit;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: shellShowsBack(context),
        title: const Text('Équipe'),
        actions: [
          if (editing)
            TextButton(
              key: const Key('doneEditingTeamButton'),
              onPressed: () => setState(() => _editing = false),
              child: const Text('Terminé'),
            )
          else if (canEdit)
            IconButton(
              key: const Key('editTeamButton'),
              tooltip: 'Modifier l\'équipe',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: switch ((value, detail.error)) {
            (final StayDetailDto detail, _) => _StayView(
              stayId: stayId,
              detail: detail,
              editing: editing,
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

  /// En lecture seule, ni bouton d'ajout ni bouton de retrait.
  final bool editing;

  const _StayView({
    required this.stayId,
    required this.detail,
    required this.editing,
  });

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
        title: Text('${_texts(role).remove} ?'),
        content: Text(
          '${member.fullName} ne fera plus partie '
          '${role == StaffRole.animator ? 'de l\'équipe' : 'de la direction'} '
          'de « ${detail.stay.name} ».',
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
          : '${staffRoleLabel(role)} retiré.',
    );
  }

  /// Les libellés d'une section, selon le rôle, et le nom du rôle dans les
  /// clés de ses widgets (`addDeputyButton`, `noDeputies`…).
  static ({
    String key,
    String keys,
    String none,
    String remove,
    String add,
    IconData icon,
  })
  _texts(StaffRole role) => switch (role) {
    StaffRole.director => (
      key: 'Director',
      keys: 'Directors',
      none: 'Aucun directeur',
      remove: 'Retirer ce directeur',
      add: 'Ajouter un directeur',
      icon: Icons.workspace_premium_outlined,
    ),
    StaffRole.deputy => (
      key: 'Deputy',
      keys: 'Deputies',
      none: 'Aucun adjoint',
      remove: 'Retirer cet adjoint',
      add: 'Ajouter un adjoint',
      icon: Icons.person_outline,
    ),
    StaffRole.animator => (
      key: 'Animator',
      keys: 'Animators',
      none: 'Aucun animateur',
      remove: 'Retirer cet animateur',
      add: 'Ajouter un animateur',
      icon: Icons.emoji_people_outlined,
    ),
  };

  /// Un message remplace le précédent au lieu d'attendre qu'il disparaisse.
  static void _tell(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

  /// Les directeurs, les adjoints ou les animateurs : un titre, chaque
  /// membre (retirable si [canManage]) et de quoi en nommer un autre.
  List<Widget> _section(
    BuildContext context,
    WidgetRef ref, {
    required StaffRole role,
    required String title,
    required List<TeamMemberDto> members,
    required bool canManage,
  }) {
    final theme = Theme.of(context);
    final texts = _texts(role);
    return [
      Text(title, style: theme.textTheme.titleSmall),
      if (members.isEmpty)
        ListTile(
          key: Key('no${texts.keys}'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline),
          title: Text(
            texts.none,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      for (final member in members)
        ListTile(
          key: Key('${role.name}-${member.id}'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(texts.icon),
          title: Text(member.fullName),
          trailing: canManage
              ? IconButton(
                  key: Key('remove${texts.key}-${member.id}'),
                  tooltip: texts.remove,
                  icon: const Icon(Icons.person_remove_outlined),
                  onPressed: () => _remove(context, ref, role, member),
                )
              : null,
        ),
      if (canManage)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: Key('add${texts.key}Button'),
            onPressed: () => _name(context, role),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(texts.add),
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
        if (stay.kind != StayKind.acm)
          Text(
            'Séjour hors ACM : il n\'a ni direction ni animateurs.',
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
            canManage: editing && detail.canManageDirectors,
          ),
          const SizedBox(height: 16),
          ..._section(
            context,
            ref,
            role: StaffRole.deputy,
            title: 'Adjoints',
            members: detail.deputies,
            canManage: editing && detail.canManageDeputies,
          ),
          const SizedBox(height: 16),
          ..._section(
            context,
            ref,
            role: StaffRole.animator,
            title: 'Animateurs',
            members: detail.animators,
            canManage: editing && detail.canManageAnimators,
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
