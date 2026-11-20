import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/news.dto.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_news.provider.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';
import 'package:lecoteaufleuri/ui/pages/news/photo_viewer.page.dart';
import 'package:lecoteaufleuri/ui/pages/news/widgets/news_retry.widget.dart';
import 'package:lecoteaufleuri/ui/pages/news/widgets/photo_image.widget.dart';

/// Les nouvelles d'un séjour : ses jours publiés, du plus récent au plus
/// ancien, chacun avec son résumé et ses photos. C'est ce que voient les
/// familles ; un jour programmé y paraît de lui-même à son heure.
class NewsFeedPage extends ConsumerWidget {
  final String stayId;

  /// Dit à la direction qu'elle voit l'écran des familles.
  final bool asFamilies;

  const NewsFeedPage({
    super.key,
    required this.stayId,
    this.asFamilies = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(stayNewsProvider(stayId));
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelles du séjour')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: switch ((news.value, news.error)) {
            (final List<PublishedDayDto> days, _) => RefreshIndicator(
              onRefresh: () => ref.refresh(stayNewsProvider(stayId).future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (asFamilies) ...[
                    Text(
                      'Ce que voient les familles : les jours publiés, du '
                      'plus récent au plus ancien.',
                      key: const Key('familiesView'),
                      style: muted,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (days.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Text(
                        'Aucune nouvelle pour l\'instant : les journées '
                        'apparaîtront ici dès leur publication.',
                        key: const Key('noNews'),
                        textAlign: TextAlign.center,
                        style: muted,
                      ),
                    ),
                  for (final day in days) _DayCard(stayId: stayId, day: day),
                ],
              ),
            ),
            (_, final Object error) => NewsRetryView.of(
              error,
              onRetry: () => ref.invalidate(stayNewsProvider(stayId)),
            ),
            _ => const CircularProgressIndicator(),
          },
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String stayId;
  final PublishedDayDto day;

  const _DayCard({required this.stayId, required this.day});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: Key('news-${day.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(displayNewsDay(day.date), style: theme.textTheme.titleLarge),
            if (day.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(day.summary, style: theme.textTheme.bodyLarge),
            ],
            if (day.photoIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: photoGridDelegate(),
                itemCount: day.photoIds.length,
                itemBuilder: (context, index) => PhotoTile(
                  key: Key('newsPhoto-${day.photoIds[index]}'),
                  stayId: stayId,
                  photoId: day.photoIds[index],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PhotoViewerPage(
                        stayId: stayId,
                        photoIds: day.photoIds,
                        initialIndex: index,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
