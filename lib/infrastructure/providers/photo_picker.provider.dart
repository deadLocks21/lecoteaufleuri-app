import 'package:lecoteaufleuri/core/domain/services/photo_picker.service.dart';
import 'package:lecoteaufleuri/infrastructure/news/image_picker.photo_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_picker.provider.g.dart';

/// La galerie de l'appareil ; les tests y substituent un choix tout fait.
@Riverpod(keepAlive: true)
PhotoPicker photoPicker(Ref ref) => ImagePickerPhotoPicker();
