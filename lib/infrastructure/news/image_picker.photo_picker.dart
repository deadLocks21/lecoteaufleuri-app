import 'package:image_picker/image_picker.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/core/domain/services/photo_picker.service.dart';

/// [PhotoPicker] sur la galerie de l'appareil (`image_picker`) : plusieurs
/// photos à la fois, réduites à 2048 points et recompressées en JPEG là où la
/// plateforme le permet (iOS, Android), pour rester loin des 10 Mo de l'API.
class ImagePickerPhotoPicker implements PhotoPicker {
  final ImagePicker _picker;

  ImagePickerPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  @override
  Future<List<PickedPhoto>> pick() async {
    final files = await _picker.pickMultiImage(
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    return [
      for (final file in files)
        PickedPhoto(name: file.name, bytes: await file.readAsBytes()),
    ];
  }
}
