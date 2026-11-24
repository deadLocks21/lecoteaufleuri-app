import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';

/// Déconnecte après confirmation : un appui malheureux ne doit pas obliger à
/// redemander un code par SMS.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  // Lu avant l'attente : le widget appelant peut disparaître entre-temps.
  final session = ref.read(sessionControllerProvider.notifier);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Se déconnecter ?'),
      content: const Text(
        'Il faudra recevoir un nouveau code par SMS pour revenir.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('confirmLogout'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Se déconnecter'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) await session.logout();
}
