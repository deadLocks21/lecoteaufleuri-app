import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/news/days.page.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_feed.page.dart';
import 'package:lecoteaufleuri/ui/pages/news/photos.page.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay_modules.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay_space_view.dart';
import 'package:lecoteaufleuri/ui/shell/app_shell.dart';

/// Le module Nouvelles d'un séjour, en onglets selon le rôle (cf. `ACCES.md`,
/// « Nouvelles du séjour ») :
/// - la direction (et l'admin) : les nouvelles publiées, telles que les
///   familles les voient, les journées à composer et les photos de toute
///   l'équipe ;
/// - un animateur : les nouvelles publiées et ses propres photos.
class StayNewsPage extends ConsumerWidget {
  final String stayId;

  const StayNewsPage({super.key, required this.stayId});

  static List<({String key, String label, Widget page})> _tabs(
    StaySpaceDto space, {
    required bool isAdmin,
  }) {
    final stay = space.stay;
    if (!isDirection(space, isAdmin: isAdmin)) {
      return [
        (
          key: 'publishedTab',
          label: 'Publiées',
          page: NewsFeedPage(stayId: stay.id, embedded: true),
        ),
        (
          key: 'myPhotosTab',
          label: 'Mes photos',
          page: StayPhotosPage(
            stayId: stay.id,
            title: 'Mes photos',
            embedded: true,
          ),
        ),
      ];
    }
    return [
      (
        key: 'publishedTab',
        label: 'Publiées',
        page: NewsFeedPage(stayId: stay.id, asFamilies: true, embedded: true),
      ),
      (
        key: 'daysTab',
        label: 'Journées',
        page: NewsDaysPage(stay: stay, embedded: true),
      ),
      (
        key: 'photosTab',
        label: 'Photos',
        page: StayPhotosPage(stayId: stay.id, title: 'Photos', embedded: true),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    final isAdmin = state is Authenticated && state.session.user.isAdmin;
    final showsBack = shellShowsBack(context);

    return StaySpaceView(
      stayId: stayId,
      builder: (context, space) {
        final tabs = _tabs(space, isAdmin: isAdmin);
        return DefaultTabController(
          // Une nouvelle liste d'onglets (rôle changé) repart du premier.
          key: ValueKey(tabs.length),
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: showsBack,
              title: const Text('Nouvelles'),
              bottom: TabBar(
                tabs: [
                  for (final tab in tabs)
                    Tab(key: Key(tab.key), text: tab.label),
                ],
              ),
            ),
            body: TabBarView(children: [for (final tab in tabs) tab.page]),
          ),
        );
      },
    );
  }
}
