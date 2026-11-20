import 'package:lecoteaufleuri/core/application/usecases/news.usecases.dart';

/// Les cas d'usage des nouvelles d'un séjour, regroupés pour leurs
/// contrôleurs : les photos de l'équipe, les jours de la direction et la
/// lecture.
class NewsApplicationService {
  final ListPhotosUseCase photos;
  final UploadPhotosUseCase upload;
  final SortPhotoUseCase sort;
  final DeletePhotoUseCase deletePhoto;
  final PhotoImageUseCase image;
  final ListDaysUseCase days;
  final CreateDayUseCase createDay;
  final UpdateDayUseCase updateDay;
  final DeleteDayUseCase deleteDay;
  final SetDayPhotosUseCase setDayPhotos;
  final PublishDayUseCase publishDay;
  final UnpublishDayUseCase unpublishDay;
  final ReadNewsUseCase news;

  const NewsApplicationService({
    required this.photos,
    required this.upload,
    required this.sort,
    required this.deletePhoto,
    required this.image,
    required this.days,
    required this.createDay,
    required this.updateDay,
    required this.deleteDay,
    required this.setDayPhotos,
    required this.publishDay,
    required this.unpublishDay,
    required this.news,
  });
}
