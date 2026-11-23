import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/infrastructure/providers/calendar_suggestions.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_days.page.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_subscribe.sheet.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/suggestions.page.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay_modules.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay_space_view.dart';
import 'package:lecoteaufleuri/ui/shell/app_shell.dart';

/// Le module Calendrier d'un séjour (cf. `ACCES.md`, « Calendrier du
/// séjour ») : le calendrier, jour par jour, avec les suggestions en
/// attente posées dedans. Dans la barre, pour toute l'équipe : les
/// suggestions qui attendent — toutes pour la direction (et l'admin), qui
/// les tranche ; les siennes pour un animateur — et l'abonnement depuis un
/// agenda.
class StayCalendarPage extends ConsumerWidget {
  final String stayId;

  const StayCalendarPage({super.key, required this.stayId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    final isAdmin = state is Authenticated && state.session.user.isAdmin;
    final showsBack = shellShowsBack(context);

    return StaySpaceView(
      stayId: stayId,
      builder: (context, space) {
        final direction = isDirection(space, isAdmin: isAdmin);
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: showsBack,
            // Seule la grille des heures défile, sous la barre des jours :
            // la barre du haut n'en change pas de couleur.
            notificationPredicate: (_) => false,
            title: const Text('Calendrier'),
            actions: [
              _SuggestionsButton(
                stayId: stayId,
                direction: direction,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CalendarSuggestionsPage(
                      stay: space.stay,
                      direction: direction,
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('subscribeButton'),
                tooltip: 'Voir dans mon agenda',
                icon: const Icon(Icons.event_repeat_outlined),
                onPressed: () => showCalendarSubscribeSheet(context, stayId),
              ),
            ],
          ),
          body: CalendarDaysPage(
            // Un autre rôle (droits relus) repart d'un calendrier neuf.
            key: ValueKey(direction),
            stay: space.stay,
            direction: direction,
          ),
        );
      },
    );
  }
}

/// Le bouton des suggestions, avec le nombre de celles qui attendent une
/// réponse.
class _SuggestionsButton extends ConsumerWidget {
  final String stayId;
  final bool direction;
  final VoidCallback onPressed;

  const _SuggestionsButton({
    required this.stayId,
    required this.direction,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoutées tant que le module est ouvert : le calendrier les montre, et
    // le nombre se met à jour.
    final suggestions = ref.watch(
      calendarSuggestionsControllerProvider(stayId),
    );
    final pending = suggestions.value?.where((s) => s.isPending).length ?? 0;
    return IconButton(
      key: const Key('suggestionsButton'),
      tooltip: direction
          ? 'Suggestions en attente'
          : 'Mes suggestions en attente',
      onPressed: onPressed,
      icon: Badge(
        key: const Key('pendingSuggestions'),
        isLabelVisible: pending > 0,
        label: Text('$pending'),
        child: const Icon(Icons.lightbulb_outline),
      ),
    );
  }
}
