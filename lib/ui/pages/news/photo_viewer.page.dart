import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/news.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_photos.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_error_message.dart';
import 'package:lecoteaufleuri/ui/pages/news/widgets/photo_image.widget.dart';

/// Des photos en grand, à feuilleter. Avec [canSort], on y trie chaque photo
/// (retenir, remettre à trier, écarter) et on la supprime ; avec
/// [advanceOnSort], trier passe à la suivante, pour enchaîner le tri d'une
/// série. Sans, c'est une simple visionneuse : pas d'enregistrement ni de
/// partage (cf. `ACCES.md`, les familles voient sans enregistrer).
class PhotoViewerPage extends ConsumerStatefulWidget {
  final String stayId;
  final List<String> photoIds;
  final int initialIndex;
  final bool canSort;
  final bool advanceOnSort;

  const PhotoViewerPage({
    super.key,
    required this.stayId,
    required this.photoIds,
    this.initialIndex = 0,
    this.canSort = false,
    this.advanceOnSort = false,
  });

  @override
  ConsumerState<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends ConsumerState<PhotoViewerPage> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late final List<String> _ids = [...widget.photoIds];
  late int _index = widget.initialIndex;
  bool _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _tell(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _sort(String photoId, PhotoSorting sorting) async {
    setState(() => _busy = true);
    final error = await ref
        .read(stayPhotosControllerProvider(widget.stayId).notifier)
        .sort(photoId, sorting);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) return _tell(newsErrorMessage(error));
    if (!widget.advanceOnSort) return;
    if (_index < _ids.length - 1) {
      await _pages.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.of(context).pop('Tri terminé.');
    }
  }

  Future<void> _delete(String photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette photo ?'),
        content: const Text(
          'Elle disparaît pour de bon, y compris du jour qu\'elle illustre. '
          'Pour la garder de côté, écartez-la plutôt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('confirmButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await ref
        .read(stayPhotosControllerProvider(widget.stayId).notifier)
        .delete(photoId);
    if (!mounted) return;
    if (error != null) return _tell(newsErrorMessage(error));
    if (_ids.length == 1) {
      Navigator.of(context).pop('Photo supprimée.');
      return;
    }
    setState(() {
      _ids.remove(photoId);
      _index = _index.clamp(0, _ids.length - 1);
    });
    _tell('Photo supprimée.');
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.canSort
        ? {
            for (final photo
                in ref
                        .watch(stayPhotosControllerProvider(widget.stayId))
                        .value ??
                    const <StayPhotoDto>[])
              photo.id: photo,
          }
        : const <String, StayPhotoDto>{};
    final current = _ids.isEmpty ? null : _ids[_index];
    final photo = photos[current];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${_ids.length}'),
        actions: [
          if (widget.canSort && current != null)
            IconButton(
              key: const Key('deletePhotoButton'),
              tooltip: 'Supprimer la photo',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : () => _delete(current),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: _ids.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) => InteractiveViewer(
          maxScale: 4,
          // Toute la page : une petite photo s'agrandit comme une grande.
          child: SizedBox.expand(
            child: PhotoImage(
              stayId: widget.stayId,
              photoId: _ids[index],
              size: PhotoSize.large,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      bottomNavigationBar: !widget.canSort || photo == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      [
                        if (photo.authorName != null) photo.authorName!,
                        'déposée le ${displayInstant(photo.uploadedAt)}',
                        if (photo.dayDate != null)
                          'illustre le ${displayShortDay(photo.dayDate!)}',
                      ].join(' · '),
                      key: const Key('photoDetails'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<PhotoSorting>(
                      key: const Key('sortingButtons'),
                      style: SegmentedButton.styleFrom(
                        foregroundColor: Colors.white,
                        selectedForegroundColor: Colors.black,
                        selectedBackgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: PhotoSorting.discarded,
                          icon: Icon(Icons.thumb_down_outlined),
                          label: Text('Écarter', key: Key('discardButton')),
                        ),
                        ButtonSegment(
                          value: PhotoSorting.pending,
                          icon: Icon(Icons.help_outline),
                          label: Text('À trier', key: Key('pendingButton')),
                        ),
                        ButtonSegment(
                          value: PhotoSorting.kept,
                          icon: Icon(Icons.thumb_up_outlined),
                          label: Text('Retenir', key: Key('keepButton')),
                        ),
                      ],
                      selected: {photo.sorting},
                      showSelectedIcon: false,
                      onSelectionChanged: _busy
                          ? null
                          : (selection) => _sort(photo.id, selection.single),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
