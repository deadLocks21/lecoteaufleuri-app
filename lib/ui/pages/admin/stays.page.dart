import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stays.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/admin/stay_create.page.dart';
import 'package:lecoteaufleuri/ui/pages/admin/stay_error_message.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

/// Les séjours de l'association, pour un admin : du dernier commencé (ou à
/// venir) au plus ancien, et la création d'un nouveau.
class StaysPage extends ConsumerWidget {
  const StaysPage({super.key});

  Future<void> _create(BuildContext context) async {
    final message = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const StayCreatePage()));
    if (message != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stays = ref.watch(staysControllerProvider);
    final value = stays.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Séjours')),
      floatingActionButton: value == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('newStayButton'),
              onPressed: () => _create(context),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau séjour'),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: switch ((value, stays.error)) {
            (final List<StayDto> list, _) => _StayList(stays: list),
            (_, final Object error) => _ErrorView(
              message: stayErrorMessage(
                error is StayException ? error.code : StayErrorCode.unknown,
              ),
              onRetry: () => ref.invalidate(staysControllerProvider),
            ),
            _ => const CircularProgressIndicator(),
          },
        ),
      ),
    );
  }
}

class _StayList extends StatelessWidget {
  final List<StayDto> stays;

  const _StayList({required this.stays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (stays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aucun séjour pour l\'instant : créez le premier.',
          key: const Key('emptyStays'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        for (final stay in stays)
          ListTile(
            key: Key('stay-${stay.id}'),
            leading: CircleAvatar(
              child: Icon(switch (stay.kind) {
                StayKind.acm => Icons.child_care,
                StayKind.other => Icons.groups_outlined,
              }),
            ),
            title: Text(stay.name),
            subtitle: Text(
              '${displayStayDates(stay.startsOn, stay.endsOn)} · '
              '${stayKindLabel(stay.kind)}',
            ),
          ),
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
            key: const Key('staysError'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
