// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_image.provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// L'image d'une photo, telle que l'API la sert au compte connecté. Elle ne
/// survit ni à [photoImageRetention] sans écran, ni à un changement de
/// session (déconnexion, autre compte).

@ProviderFor(photoImage)
final photoImageProvider = PhotoImageFamily._();

/// L'image d'une photo, telle que l'API la sert au compte connecté. Elle ne
/// survit ni à [photoImageRetention] sans écran, ni à un changement de
/// session (déconnexion, autre compte).

final class PhotoImageProvider
    extends
        $FunctionalProvider<
          AsyncValue<Uint8List>,
          Uint8List,
          FutureOr<Uint8List>
        >
    with $FutureModifier<Uint8List>, $FutureProvider<Uint8List> {
  /// L'image d'une photo, telle que l'API la sert au compte connecté. Elle ne
  /// survit ni à [photoImageRetention] sans écran, ni à un changement de
  /// session (déconnexion, autre compte).
  PhotoImageProvider._({
    required PhotoImageFamily super.from,
    required (String, String, PhotoSize) super.argument,
  }) : super(
         retry: null,
         name: r'photoImageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$photoImageHash();

  @override
  String toString() {
    return r'photoImageProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Uint8List> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Uint8List> create(Ref ref) {
    final argument = this.argument as (String, String, PhotoSize);
    return photoImage(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is PhotoImageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$photoImageHash() => r'aaea3200421a96e48133d83d9b89c8a866849fe0';

/// L'image d'une photo, telle que l'API la sert au compte connecté. Elle ne
/// survit ni à [photoImageRetention] sans écran, ni à un changement de
/// session (déconnexion, autre compte).

final class PhotoImageFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Uint8List>,
          (String, String, PhotoSize)
        > {
  PhotoImageFamily._()
    : super(
        retry: null,
        name: r'photoImageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// L'image d'une photo, telle que l'API la sert au compte connecté. Elle ne
  /// survit ni à [photoImageRetention] sans écran, ni à un changement de
  /// session (déconnexion, autre compte).

  PhotoImageProvider call(String stayId, String photoId, PhotoSize size) =>
      PhotoImageProvider._(argument: (stayId, photoId, size), from: this);

  @override
  String toString() => r'photoImageProvider';
}
