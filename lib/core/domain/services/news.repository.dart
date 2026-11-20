import 'dart:typed_data';

import 'package:lecoteaufleuri/core/domain/model/news.dart';

/// Port des nouvelles d'un séjour (cf. `ACCES.md` du dépôt lecoteaufleuri/dev,
/// « Nouvelles du séjour »). L'API vérifie chaque droit à chaque appel ; tout
/// échec est signalé par une `NewsException`.
abstract interface class NewsRepository {
  /// Les photos que le compte peut trier : toutes pour la direction (la
  /// pioche), les siennes pour un animateur ; dans l'ordre de la pioche.
  Future<List<StayPhoto>> photos(String stayId);

  /// Dépose une photo : elle arrive à trier. Toute l'équipe.
  Future<StayPhoto> upload(String stayId, PickedPhoto photo);

  /// Son auteur ou la direction.
  Future<StayPhoto> sort(String stayId, String photoId, PhotoSorting sorting);

  /// Définitif. Son auteur ou la direction.
  Future<void> deletePhoto(String stayId, String photoId);

  /// L'image d'une photo, si le compte peut la voir.
  Future<Uint8List> image(String stayId, String photoId, PhotoSize size);

  /// Tous les jours du séjour, du premier au dernier. La direction.
  Future<List<NewsDay>> days(String stayId);

  /// Un brouillon, à [date] (minuit UTC). La direction.
  Future<NewsDay> createDay(String stayId, DateTime date, {String summary});

  Future<NewsDay> updateDay(
    String stayId,
    String dayId, {
    required DateTime date,
    required String summary,
  });

  /// Ses photos retournent à la pioche.
  Future<void> deleteDay(String stayId, String dayId);

  /// Les photos du jour, dans cet ordre (elles remplacent les précédentes).
  Future<NewsDay> setDayPhotos(
    String stayId,
    String dayId,
    List<String> photoIds,
  );

  /// Tout de suite sans [at] (ou avec une heure passée), programmé sinon.
  Future<NewsDay> publishDay(String stayId, String dayId, {DateTime? at});

  /// Le jour redevient brouillon.
  Future<NewsDay> unpublishDay(String stayId, String dayId);

  /// Les jours publiés, du plus récent au plus ancien. Toute l'équipe.
  Future<List<PublishedDay>> news(String stayId);
}
