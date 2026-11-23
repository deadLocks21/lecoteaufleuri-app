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

/// Le module Calendrier d'un séjour, en deux onglets (cf. `ACCES.md`,
/// « Calendrier du séjour ») : le calendrier, jour par jour, et les
/// suggestions — toutes pour la direction (et l'admin), qui les tranche ;
/// les siennes pour un animateur. L'abonnement depuis un agenda est dans la
/// barre, pour toute l'équipe.
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
        return DefaultTabController(
          // Un autre rôle (droits relus) repart du premier onglet.
          key: ValueKey(direction),
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: showsBack,
              title: const Text('Calendrier'),
              actions: [
                IconButton(
                  key: const Key('subscribeButton'),
                  tooltip: 'Voir dans mon agenda',
                  icon: const Icon(Icons.event_repeat_outlined),
                  onPressed: () => showCalendarSubscribeSheet(context, stayId),
                ),
              ],
              bottom: TabBar(
                tabs: [
                  const Tab(key: Key('calendarTab'), text: 'Calendrier'),
                  Tab(
                    key: const Key('suggestionsTab'),
                    child: _SuggestionsTabLabel(
                      stayId: stayId,
                      label: direction ? 'Suggestions' : 'Mes suggestions',
                      countsPending: direction,
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                CalendarDaysPage(stay: space.stay, direction: direction),
                CalendarSuggestionsPage(stay: space.stay, direction: direction),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Le titre de l'onglet des suggestions, avec, pour la direction, le nombre
/// de celles qui attendent sa réponse.
class _SuggestionsTabLabel extends ConsumerWidget {
  final String stayId;
  final String label;
  final bool countsPending;

  const _SuggestionsTabLabel({
    required this.stayId,
    required this.label,
    required this.countsPending,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoutées tant que le module est ouvert : une suggestion envoyée depuis
    // le calendrier trouve la liste prête, et l'onglet se met à jour.
    final suggestions = ref.watch(
      calendarSuggestionsControllerProvider(stayId),
    );
    final pending = countsPending
        ? suggestions.value?.where((s) => s.isPending).length ?? 0
        : 0;
    return Badge(
      key: const Key('pendingSuggestions'),
      isLabelVisible: pending > 0,
      label: Text('$pending'),
      offset: const Offset(14, -6),
      child: Text(label),
    );
  }
}
