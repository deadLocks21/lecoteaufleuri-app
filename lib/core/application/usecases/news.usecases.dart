import 'dart:typed_data';

import 'package:lecoteaufleuri/core/application/dtos/news.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/news.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/services/news.repository.dart';
import 'package:lecoteaufleuri/core/domain/services/photo_picker.service.dart';

/// Les photos que le compte peut trier, dans l'ordre de la pioche.
class ListPhotosUseCase {
  final NewsRepository _news;

  ListPhotosUseCase(this._news);

  Future<List<StayPhotoDto>> execute(String stayId) async =>
      (await _news.photos(stayId)).map(StayPhotoDto.fromDomain).toList();
}

/// Le bilan d'un envoi de photos : celles qui sont arrivées, et la raison du
/// premier échec s'il y en a eu.
typedef UploadReport = ({
  List<StayPhotoDto> uploaded,
  int failed,
  NewsErrorCode? error,
});

/// Choisit des photos sur l'appareil puis les dépose une à une, en disant où
/// en est l'envoi : une photo refusée n'arrête pas les suivantes.
class UploadPhotosUseCase {
  final NewsRepository _news;
  final PhotoPicker _picker;

  UploadPhotosUseCase(this._news, this._picker);

  /// Null si l'on renonce au choix.
  Future<UploadReport?> execute(
    String stayId, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final picked = await _picker.pick();
    if (picked.isEmpty) return null;

    final uploaded = <StayPhotoDto>[];
    var failed = 0;
    NewsErrorCode? error;
    onProgress?.call(0, picked.length);
    for (final (index, photo) in picked.indexed) {
      try {
        uploaded.add(
          StayPhotoDto.fromDomain(await _news.upload(stayId, photo)),
        );
      } on NewsException catch (e) {
        failed++;
        error ??= e.code;
        // Sans réseau, ni droit, ni séjour, les suivantes échoueraient aussi.
        if (const {
          NewsErrorCode.network,
          NewsErrorCode.sessionExpired,
          NewsErrorCode.forbidden,
          NewsErrorCode.stayNotFound,
        }.contains(e.code)) {
          failed += picked.length - index - 1;
          break;
        }
      }
      onProgress?.call(index + 1, picked.length);
    }
    return (uploaded: uploaded, failed: failed, error: error);
  }
}

class SortPhotoUseCase {
  final NewsRepository _news;

  SortPhotoUseCase(this._news);

  Future<StayPhotoDto> execute(
    String stayId,
    String photoId,
    PhotoSorting sorting,
  ) async =>
      StayPhotoDto.fromDomain(await _news.sort(stayId, photoId, sorting));
}

class DeletePhotoUseCase {
  final NewsRepository _news;

  DeletePhotoUseCase(this._news);

  Future<void> execute(String stayId, String photoId) =>
      _news.deletePhoto(stayId, photoId);
}

class PhotoImageUseCase {
  final NewsRepository _news;

  PhotoImageUseCase(this._news);

  Future<Uint8List> execute(String stayId, String photoId, PhotoSize size) =>
      _news.image(stayId, photoId, size);
}

class ListDaysUseCase {
  final NewsRepository _news;

  ListDaysUseCase(this._news);

  Future<List<NewsDayDto>> execute(String stayId) async =>
      (await _news.days(stayId)).map(NewsDayDto.fromDomain).toList();
}

/// Crée un jour à [date] (seuls l'année, le mois et le jour comptent).
class CreateDayUseCase {
  final NewsRepository _news;

  CreateDayUseCase(this._news);

  Future<NewsDayDto> execute(String stayId, DateTime date) async =>
      NewsDayDto.fromDomain(await _news.createDay(stayId, calendarDay(date)));
}

/// Change la date et le résumé d'un jour, même publié.
class UpdateDayUseCase {
  final NewsRepository _news;

  UpdateDayUseCase(this._news);

  Future<NewsDayDto> execute(
    String stayId,
    String dayId, {
    required DateTime date,
    required String summary,
  }) async => NewsDayDto.fromDomain(
    await _news.updateDay(
      stayId,
      dayId,
      date: calendarDay(date),
      summary: summary.trim(),
    ),
  );
}

class DeleteDayUseCase {
  final NewsRepository _news;

  DeleteDayUseCase(this._news);

  Future<void> execute(String stayId, String dayId) =>
      _news.deleteDay(stayId, dayId);
}

class SetDayPhotosUseCase {
  final NewsRepository _news;

  SetDayPhotosUseCase(this._news);

  Future<NewsDayDto> execute(
    String stayId,
    String dayId,
    List<String> photoIds,
  ) async =>
      NewsDayDto.fromDomain(await _news.setDayPhotos(stayId, dayId, photoIds));
}

/// Publie un jour tout de suite, ou à [at] (programmé).
class PublishDayUseCase {
  final NewsRepository _news;

  PublishDayUseCase(this._news);

  Future<NewsDayDto> execute(
    String stayId,
    String dayId, {
    DateTime? at,
  }) async =>
      NewsDayDto.fromDomain(await _news.publishDay(stayId, dayId, at: at));
}

class UnpublishDayUseCase {
  final NewsRepository _news;

  UnpublishDayUseCase(this._news);

  Future<NewsDayDto> execute(String stayId, String dayId) async =>
      NewsDayDto.fromDomain(await _news.unpublishDay(stayId, dayId));
}

/// Les jours publiés, du plus récent au plus ancien.
class ReadNewsUseCase {
  final NewsRepository _news;

  ReadNewsUseCase(this._news);

  Future<List<PublishedDayDto>> execute(String stayId) async =>
      (await _news.news(stayId)).map(PublishedDayDto.fromDomain).toList();
}
