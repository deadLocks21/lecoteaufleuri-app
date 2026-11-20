// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stay_space.provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le séjour ouvert, et le rôle qu'y tient le compte connecté.
///
/// Un séjour de « Mes séjours » s'ouvre avec son rôle ; un autre (un admin
/// qui l'a choisi dans la liste de l'association) se lit auprès de l'API, qui
/// refuse à qui n'y a pas droit. Sans `keepAlive`, comme [myStays].

@ProviderFor(staySpace)
final staySpaceProvider = StaySpaceFamily._();

/// Le séjour ouvert, et le rôle qu'y tient le compte connecté.
///
/// Un séjour de « Mes séjours » s'ouvre avec son rôle ; un autre (un admin
/// qui l'a choisi dans la liste de l'association) se lit auprès de l'API, qui
/// refuse à qui n'y a pas droit. Sans `keepAlive`, comme [myStays].

final class StaySpaceProvider
    extends
        $FunctionalProvider<
          AsyncValue<StaySpaceDto>,
          StaySpaceDto,
          FutureOr<StaySpaceDto>
        >
    with $FutureModifier<StaySpaceDto>, $FutureProvider<StaySpaceDto> {
  /// Le séjour ouvert, et le rôle qu'y tient le compte connecté.
  ///
  /// Un séjour de « Mes séjours » s'ouvre avec son rôle ; un autre (un admin
  /// qui l'a choisi dans la liste de l'association) se lit auprès de l'API, qui
  /// refuse à qui n'y a pas droit. Sans `keepAlive`, comme [myStays].
  StaySpaceProvider._({
    required StaySpaceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'staySpaceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$staySpaceHash();

  @override
  String toString() {
    return r'staySpaceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<StaySpaceDto> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StaySpaceDto> create(Ref ref) {
    final argument = this.argument as String;
    return staySpace(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StaySpaceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$staySpaceHash() => r'49a58df68fbae7e468310373a5fa78639932644e';

/// Le séjour ouvert, et le rôle qu'y tient le compte connecté.
///
/// Un séjour de « Mes séjours » s'ouvre avec son rôle ; un autre (un admin
/// qui l'a choisi dans la liste de l'association) se lit auprès de l'API, qui
/// refuse à qui n'y a pas droit. Sans `keepAlive`, comme [myStays].

final class StaySpaceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<StaySpaceDto>, String> {
  StaySpaceFamily._()
    : super(
        retry: null,
        name: r'staySpaceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Le séjour ouvert, et le rôle qu'y tient le compte connecté.
  ///
  /// Un séjour de « Mes séjours » s'ouvre avec son rôle ; un autre (un admin
  /// qui l'a choisi dans la liste de l'association) se lit auprès de l'API, qui
  /// refuse à qui n'y a pas droit. Sans `keepAlive`, comme [myStays].

  StaySpaceProvider call(String stayId) =>
      StaySpaceProvider._(argument: stayId, from: this);

  @override
  String toString() => r'staySpaceProvider';
}
