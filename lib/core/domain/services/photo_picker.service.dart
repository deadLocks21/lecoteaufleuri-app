import 'package:lecoteaufleuri/core/domain/model/news.dart';

/// Port du choix de photos sur l'appareil (galerie, fichiers).
abstract interface class PhotoPicker {
  /// Les photos choisies, réduites pour l'envoi ; vide si l'on renonce.
  Future<List<PickedPhoto>> pick();
}
