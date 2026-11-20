import 'package:lecoteaufleuri/core/application/services/news_application.service.dart';
import 'package:lecoteaufleuri/core/application/usecases/news.usecases.dart';
import 'package:lecoteaufleuri/infrastructure/providers/news.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/photo_picker.provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'news.service_provider.g.dart';

@Riverpod(keepAlive: true)
NewsApplicationService newsService(Ref ref) {
  final news = ref.watch(newsRepositoryProvider);
  return NewsApplicationService(
    photos: ListPhotosUseCase(news),
    upload: UploadPhotosUseCase(news, ref.watch(photoPickerProvider)),
    sort: SortPhotoUseCase(news),
    deletePhoto: DeletePhotoUseCase(news),
    image: PhotoImageUseCase(news),
    days: ListDaysUseCase(news),
    createDay: CreateDayUseCase(news),
    updateDay: UpdateDayUseCase(news),
    deleteDay: DeleteDayUseCase(news),
    setDayPhotos: SetDayPhotosUseCase(news),
    publishDay: PublishDayUseCase(news),
    unpublishDay: UnpublishDayUseCase(news),
    news: ReadNewsUseCase(news),
  );
}
