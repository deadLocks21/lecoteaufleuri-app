import 'package:flutter/foundation.dart';
import 'package:lecoteaufleuri/core/application/dtos/news.dto.dart';
import 'package:lecoteaufleuri/core/application/services/news_application.service.dart';
import 'package:lecoteaufleuri/core/application/usecases/news.usecases.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/news.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/infrastructure/providers/news.service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stay_photos.controller_provider.g.dart';

/// Les photos d'un séjour que le compte peut trier (toutes pour la direction,
/// les siennes pour un animateur), et de quoi en déposer, les trier ou les
/// supprimer.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de
/// `keepAlive`). Les actions rendent `null` en cas de succès, sinon le
/// [NewsErrorCode] que l'écran traduit.
@riverpod
class StayPhotosController extends _$StayPhotosController {
  NewsApplicationService get _service => ref.read(newsServiceProvider);

  @override
  Future<List<StayPhotoDto>> build(String stayId) =>
      ref.watch(newsServiceProvider).photos.execute(stayId);

  /// Choisit des photos sur l'appareil et les dépose ; null si l'on renonce.
  Future<UploadReport?> upload({
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final report = await _service.upload.execute(
        stayId,
        onProgress: onProgress,
      );
      if (report != null && report.uploaded.isNotEmpty && ref.mounted) {
        _replace([...?state.value, ...report.uploaded]);
      }
      return report;
    } catch (e, stack) {
      debugPrint('photos : échec inattendu du dépôt : $e\n$stack');
      return (
        uploaded: <StayPhotoDto>[],
        failed: 1,
        error: NewsErrorCode.unknown,
      );
    }
  }

  Future<NewsErrorCode?> sort(String photoId, PhotoSorting sorting) =>
      _run(() async {
        final sorted = await _service.sort.execute(stayId, photoId, sorting);
        _replace([
          for (final photo in state.value ?? const <StayPhotoDto>[])
            photo.id == photoId ? sorted : photo,
        ]);
      });

  Future<NewsErrorCode?> delete(String photoId) => _run(() async {
    await _service.deletePhoto.execute(stayId, photoId);
    _replace([
      for (final photo in state.value ?? const <StayPhotoDto>[])
        if (photo.id != photoId) photo,
    ]);
  });

  /// Garde l'ordre de la pioche, celui de l'API.
  void _replace(List<StayPhotoDto> photos) {
    if (!ref.mounted) return;
    state = AsyncData(
      [...photos]..sort(
        (a, b) => switch (a.sorting.priority.compareTo(b.sorting.priority)) {
          0 => switch (b.uploadedAt.compareTo(a.uploadedAt)) {
            0 => a.id.compareTo(b.id),
            final byDate => byDate,
          },
          final byPriority => byPriority,
        },
      ),
    );
  }

  Future<NewsErrorCode?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on NewsException catch (e) {
      // Photo disparue, ou droits retirés : on relit ce qu'on peut encore voir.
      if (const {
            NewsErrorCode.photoNotFound,
            NewsErrorCode.stayNotFound,
            NewsErrorCode.forbidden,
          }.contains(e.code) &&
          ref.mounted) {
        ref.invalidateSelf();
      }
      return e.code;
    } catch (e, stack) {
      debugPrint('photos : échec inattendu : $e\n$stack');
      return NewsErrorCode.unknown;
    }
  }
}
