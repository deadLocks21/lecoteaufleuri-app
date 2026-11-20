import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/infrastructure/providers/news.service_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_image.provider.g.dart';

/// Combien de temps une image reste en mémoire après le dernier écran qui
/// l'affiche : revenir sur une grille ne la retélécharge pas.
const photoImageRetention = Duration(minutes: 5);

/// L'image d'une photo, telle que l'API la sert au compte connecté. Elle ne
/// survit ni à [photoImageRetention] sans écran, ni à un changement de
/// session (déconnexion, autre compte).
@riverpod
Future<Uint8List> photoImage(
  Ref ref,
  String stayId,
  String photoId,
  PhotoSize size,
) async {
  ref.watch(
    sessionControllerProvider.select(
      (state) => state is Authenticated ? state.session.user.id : null,
    ),
  );
  final link = ref.keepAlive();
  final timer = Timer(photoImageRetention, link.close);
  ref.onDispose(timer.cancel);
  return ref.watch(newsServiceProvider).image.execute(stayId, photoId, size);
}
