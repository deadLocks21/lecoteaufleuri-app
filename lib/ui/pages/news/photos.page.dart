import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/news.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/news.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_photos.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_error_message.dart';
import 'package:lecoteaufleuri/ui/pages/news/photo_viewer.page.dart';
import 'package:lecoteaufleuri/ui/pages/news/widgets/news_retry.widget.dart';
import 'package:lecoteaufleuri/ui/pages/news/widgets/photo_image.widget.dart';

/// Les photos d'un séjour que le compte peut trier : les siennes pour un
/// animateur, toutes pour la direction. On y en dépose, on les trie (en série
/// pour celles qui attendent), on les ouvre en grand. Retenues d'abord, puis à
/// trier, puis écartées : l'ordre de la pioche.
class StayPhotosPage extends ConsumerStatefulWidget {
  final String stayId;
  final String title;

  /// Affichée dans un onglet du module Nouvelles, sous sa barre : sans barre
  /// de titre à elle.
  final bool embedded;

  const StayPhotosPage({
    super.key,
    required this.stayId,
    required this.title,
    this.embedded = false,
  });

  @override
  ConsumerState<StayPhotosPage> createState() => _StayPhotosPageState();
}

class _StayPhotosPageState extends ConsumerState<StayPhotosPage> {
  /// Où en est un envoi en cours : (envoyées, à envoyer).
  (int, int)? _progress;
  bool _uploading = false;

  void _tell(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _upload() async {
    setState(() => _uploading = true);
    final report = await ref
        .read(stayPhotosControllerProvider(widget.stayId).notifier)
        .upload(
          onProgress: (sent, total) {
            if (mounted) setState(() => _progress = (sent, total));
          },
        );
    if (!mounted) return;
    setState(() {
      _uploading = false;
      _progress = null;
    });
    if (report == null) return;
    final sent = report.uploaded.length;
    final added = sent == 1 ? '1 photo ajoutée' : '$sent photos ajoutées';
    _tell(switch (report) {
      (failed: 0, :final uploaded, error: _) when uploaded.isNotEmpty =>
        '$added, à trier.',
      (:final failed, :final error, uploaded: _) =>
        '${sent == 0 ? 'Aucune photo ajoutée' : added} : '
            '${failed == 1 ? '1 n\'a' : '$failed n\'ont'} pas pu être envoyée'
            '${failed == 1 ? '' : 's'}. '
            '${newsErrorMessage(error ?? NewsErrorCode.unknown)}',
    });
  }

  Future<void> _open(List<String> ids, int index, {bool series = false}) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PhotoViewerPage(
          stayId: widget.stayId,
          photoIds: ids,
          initialIndex: index,
          canSort: true,
          advanceOnSort: series,
        ),
      ),
    );
    if (message != null && mounted) _tell(message);
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(stayPhotosControllerProvider(widget.stayId));
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addPhotosButton'),
        onPressed: _uploading ? null : _upload,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Ajouter des photos'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: switch ((photos.value, photos.error)) {
            (final List<StayPhotoDto> list, _) => RefreshIndicator(
              onRefresh: () => ref.refresh(
                stayPhotosControllerProvider(widget.stayId).future,
              ),
              child: _grid(context, list, muted),
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

  Widget _grid(
    BuildContext context,
    List<StayPhotoDto> list,
    TextStyle? muted,
  ) {
    final ids = [for (final photo in list) photo.id];
    final pending = [
      for (final photo in list)
        if (photo.sorting == PhotoSorting.pending) photo.id,
    ];
    final progress = _progress;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (progress != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    key: const Key('uploadProgress'),
                    value: progress.$2 == 0 ? null : progress.$1 / progress.$2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Envoi des photos : ${progress.$1} sur ${progress.$2}…',
                    style: muted,
                  ),
                ],
              ),
            ),
          ),
        if (pending.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: FilledButton.tonalIcon(
                key: const Key('sortPendingButton'),
                onPressed: () => _open(pending, 0, series: true),
                icon: const Icon(Icons.swipe_outlined),
                label: Text(
                  pending.length == 1
                      ? 'Trier la photo qui attend'
                      : 'Trier les ${pending.length} photos qui attendent',
                ),
              ),
            ),
          ),
        if (list.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Aucune photo pour l\'instant. Ajoutez celles de la journée : '
                  'vous les trierez ensuite, et la direction y piochera pour '
                  'les nouvelles.',
                  key: const Key('noPhotos'),
                  textAlign: TextAlign.center,
                  style: muted,
                ),
              ),
            ),
          ),
        for (final sorting in [
          PhotoSorting.kept,
          PhotoSorting.pending,
          PhotoSorting.discarded,
        ])
          ..._section(context, sorting, [
            for (final photo in list)
              if (photo.sorting == sorting) photo,
          ], ids),
        // Laisse le dernier rang hors du bouton flottant.
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  List<Widget> _section(
    BuildContext context,
    PhotoSorting sorting,
    List<StayPhotoDto> photos,
    List<String> ids,
  ) {
    if (photos.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            '${photoSortingTitle(sorting)} · ${photos.length}',
            key: Key('photoSection-${sorting.name}'),
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
            return PhotoTile(
              key: Key('photo-${photo.id}'),
              stayId: widget.stayId,
              photoId: photo.id,
              badge: photo.dayDate == null
                  ? null
                  : displayShortDay(photo.dayDate!),
              onTap: () => _open(ids, ids.indexOf(photo.id)),
            );
          },
        ),
      ),
    ];
  }
}
