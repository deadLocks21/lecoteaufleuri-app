import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/news.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_photos.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';
import 'package:lecoteaufleuri/ui/pages/news/widgets/news_retry.widget.dart';
import 'package:lecoteaufleuri/ui/pages/news/widgets/photo_image.widget.dart';

/// La pioche : la direction choisit les photos d'un jour parmi toutes celles
/// du séjour, les retenues d'abord, puis celles à trier, et les écartées en
/// dernier recours (repliées). Une photo qui illustre un autre jour est grisée.
///
/// Rend les photos choisies, dans l'ordre du choix (celles déjà dans le jour
/// gardent leur place) ; null si l'on renonce.
class PhotoPoolPage extends ConsumerStatefulWidget {
  final String stayId;
  final String dayId;
  final List<String> selected;

  const PhotoPoolPage({
    super.key,
    required this.stayId,
    required this.dayId,
    required this.selected,
  });

  @override
  ConsumerState<PhotoPoolPage> createState() => _PhotoPoolPageState();
}

class _PhotoPoolPageState extends ConsumerState<PhotoPoolPage> {
  late final List<String> _selected = [...widget.selected];
  bool _showDiscarded = false;

  void _toggle(StayPhotoDto photo) {
    if (photo.dayId != null && photo.dayId != widget.dayId) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Cette photo illustre déjà le ${displayNewsDay(photo.dayDate!).toLowerCase()}.',
            ),
          ),
        );
      return;
    }
    setState(() {
      if (!_selected.remove(photo.id)) _selected.add(photo.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(stayPhotosControllerProvider(widget.stayId));
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Choisir les photos')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            key: const Key('confirmPickButton'),
            onPressed: () => Navigator.of(context).pop(_selected),
            child: Text('Valider · ${photoCount(_selected.length)}'),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: switch ((photos.value, photos.error)) {
            (final List<StayPhotoDto> list, _) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      'Touchez les photos dans l\'ordre où elles paraîtront. '
                      'Les retenues d\'abord ; les écartées en dernier recours.',
                      style: muted,
                    ),
                  ),
                ),
                if (list.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'L\'équipe n\'a déposé aucune photo pour l\'instant.',
                        key: const Key('emptyPool'),
                        textAlign: TextAlign.center,
                        style: muted,
                      ),
                    ),
                  ),
                ..._section(context, list, PhotoSorting.kept),
                ..._section(context, list, PhotoSorting.pending),
                if (list.any((p) => p.sorting == PhotoSorting.discarded)) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                      child: TextButton.icon(
                        key: const Key('toggleDiscardedButton'),
                        onPressed: () =>
                            setState(() => _showDiscarded = !_showDiscarded),
                        icon: Icon(
                          _showDiscarded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        label: Text(
                          _showDiscarded
                              ? 'Masquer les photos écartées'
                              : 'Voir les photos écartées (dernier recours)',
                        ),
                      ),
                    ),
                  ),
                  if (_showDiscarded)
                    ..._section(context, list, PhotoSorting.discarded),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
            (_, final Object error) => NewsRetryView.of(
              error,
              onRetry: () =>
                  ref.invalidate(stayPhotosControllerProvider(widget.stayId)),
            ),
            _ => const CircularProgressIndicator(),
          },
        ),
      ),
    );
  }

  List<Widget> _section(
    BuildContext context,
    List<StayPhotoDto> all,
    PhotoSorting sorting,
  ) {
    final photos = [
      for (final photo in all)
        if (photo.sorting == sorting) photo,
    ];
    if (photos.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '${photoSortingTitle(sorting)} · ${photos.length}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid.builder(
          gridDelegate: photoGridDelegate(),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            final elsewhere =
                photo.dayId != null && photo.dayId != widget.dayId;
            final rank = _selected.indexOf(photo.id);
            return PhotoTile(
              key: Key('pick-${photo.id}'),
              stayId: widget.stayId,
              photoId: photo.id,
              dimmed: elsewhere,
              badge: elsewhere ? displayShortDay(photo.dayDate!) : null,
              selectedRank: rank < 0 ? null : rank + 1,
              onTap: () => _toggle(photo),
            );
          },
        ),
      ),
    ];
  }
}
