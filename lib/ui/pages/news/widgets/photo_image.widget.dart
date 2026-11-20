import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/infrastructure/providers/photo_image.provider.dart';

/// L'image d'une photo, servie par l'API au compte connecté : un aplat
/// pendant le chargement, une icône si elle n'a pas pu l'être.
class PhotoImage extends ConsumerWidget {
  final String stayId;
  final String photoId;
  final PhotoSize size;
  final BoxFit fit;

  const PhotoImage({
    super.key,
    required this.stayId,
    required this.photoId,
    this.size = PhotoSize.thumbnail,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(photoImageProvider(stayId, photoId, size));
    final colors = Theme.of(context).colorScheme;
    final large = size == PhotoSize.large;
    final placeholder = large
        ? Colors.transparent
        : colors.surfaceContainerHighest;

    return switch (image) {
      AsyncData(:final value) => Image.memory(
        value,
        key: Key('photoImage-$photoId'),
        fit: fit,
        gaplessPlayback: true,
        // Une vignette n'a pas besoin d'être décodée en entier.
        cacheWidth: large ? null : 400,
        errorBuilder: (_, _, _) => _Broken(color: placeholder),
      ),
      AsyncError() => _Broken(color: placeholder),
      _ => ColoredBox(
        color: placeholder,
        child: large
            ? const Center(child: CircularProgressIndicator())
            : const SizedBox.expand(),
      ),
    };
  }
}

class _Broken extends StatelessWidget {
  final Color color;

  const _Broken({required this.color});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

/// Une vignette carrée et cliquable, avec ses éventuels marqueurs : le jour
/// qu'elle illustre ([badge]), son rang dans une sélection ([selectedRank]),
/// ou grisée si elle n'est pas disponible ([dimmed]).
class PhotoTile extends StatelessWidget {
  final String stayId;
  final String photoId;
  final VoidCallback? onTap;
  final String? badge;
  final int? selectedRank;
  final bool dimmed;

  const PhotoTile({
    super.key,
    required this.stayId,
    required this.photoId,
    this.onTap,
    this.badge,
    this.selectedRank,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = selectedRank != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: dimmed ? 0.4 : 1,
            child: PhotoImage(stayId: stayId, photoId: photoId),
          ),
          if (selected)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.primary, width: 4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          if (badge != null)
            Positioned(
              left: 4,
              bottom: 4,
              child: _Pill(text: badge!, icon: Icons.event_outlined),
            ),
          if (selected)
            Positioned(
              right: 4,
              top: 4,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                child: Text(
                  '$selectedRank',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: colors.onPrimary),
                ),
              ),
            ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(onTap: onTap),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Pill({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 3),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    ),
  );
}

/// Une grille de vignettes qui s'adapte à la largeur (au moins 3 colonnes).
SliverGridDelegate photoGridDelegate() =>
    const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 160,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
    );
