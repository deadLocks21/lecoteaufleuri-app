import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';

/// Accueil, réservé aux comptes connectés (cf. `AuthGate`).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    final firstName = state is Authenticated
        ? state.session.user.firstName
        : '';

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
        child: Text(
          'Bonjour $firstName !',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
