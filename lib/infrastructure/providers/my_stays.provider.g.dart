// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_stays.provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Les séjours où le compte connecté est directeur ou adjoint, pour l'accueil.
///
/// Sans `keepAlive` : libéré avec l'accueil, donc à la déconnexion. L'accueil
/// le relit quand les droits du compte sont relus.

@ProviderFor(myStays)
final myStaysProvider = MyStaysProvider._();

/// Les séjours où le compte connecté est directeur ou adjoint, pour l'accueil.
///
/// Sans `keepAlive` : libéré avec l'accueil, donc à la déconnexion. L'accueil
/// le relit quand les droits du compte sont relus.

final class MyStaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MyStayDto>>,
          List<MyStayDto>,
          FutureOr<List<MyStayDto>>
        >
    with $FutureModifier<List<MyStayDto>>, $FutureProvider<List<MyStayDto>> {
  /// Les séjours où le compte connecté est directeur ou adjoint, pour l'accueil.
  ///
  /// Sans `keepAlive` : libéré avec l'accueil, donc à la déconnexion. L'accueil
  /// le relit quand les droits du compte sont relus.
  MyStaysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myStaysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myStaysHash();

  @$internal
  @override
  $FutureProviderElement<List<MyStayDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MyStayDto>> create(Ref ref) {
    return myStays(ref);
  }
}

String _$myStaysHash() => r'3b1b1579e5757de59d59e72bc34d4451e4c13083';
