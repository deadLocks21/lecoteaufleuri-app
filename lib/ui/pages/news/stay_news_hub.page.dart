import 'package:flutter/material.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_feed.page.dart';
import 'package:lecoteaufleuri/ui/pages/news/photos.page.dart';
import 'package:lecoteaufleuri/ui/widgets/space_card.widget.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

/// Le séjour d'un animateur : il n'en ouvre pas la fiche (l'équipe est
/// l'affaire de la direction), mais y dépose et trie ses photos, et lit les
/// nouvelles publiées.
class StayNewsHubPage extends StatelessWidget {
  final StayDto stay;

  const StayNewsHubPage({super.key, required this.stay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(stay.name)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                displayStayDates(stay.startsOn, stay.endsOn),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              SpaceCard(
                key: const Key('myPhotosSpace'),
                icon: Icons.photo_library_outlined,
                title: 'Mes photos',
                subtitle: 'Déposer vos photos et les trier pour la direction',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        StayPhotosPage(stayId: stay.id, title: 'Mes photos'),
                  ),
                ),
              ),
              SpaceCard(
                key: const Key('newsFeedSpace'),
                icon: Icons.newspaper_outlined,
                title: 'Nouvelles du séjour',
                subtitle: 'Les journées publiées pour les familles',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NewsFeedPage(stayId: stay.id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
