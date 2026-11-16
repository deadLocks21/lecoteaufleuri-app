// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pilote la [SessionState] : seul point de contact entre l'UI et les cas
/// d'usage de connexion.
///
/// Les actions rendent `null` en cas de succès, sinon l'[AuthErrorCode] que
/// l'écran traduit en message.

@ProviderFor(SessionController)
final sessionControllerProvider = SessionControllerProvider._();

/// Pilote la [SessionState] : seul point de contact entre l'UI et les cas
/// d'usage de connexion.
///
/// Les actions rendent `null` en cas de succès, sinon l'[AuthErrorCode] que
/// l'écran traduit en message.
final class SessionControllerProvider
    extends $NotifierProvider<SessionController, SessionState> {
  /// Pilote la [SessionState] : seul point de contact entre l'UI et les cas
  /// d'usage de connexion.
  ///
  /// Les actions rendent `null` en cas de succès, sinon l'[AuthErrorCode] que
  /// l'écran traduit en message.
  SessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionControllerHash();

  @$internal
  @override
  SessionController create() => SessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionState>(value),
    );
  }
}

String _$sessionControllerHash() => r'1f8545105899bdaa298c9260f6a3eceddd6a7055';

/// Pilote la [SessionState] : seul point de contact entre l'UI et les cas
/// d'usage de connexion.
///
/// Les actions rendent `null` en cas de succès, sinon l'[AuthErrorCode] que
/// l'écran traduit en message.

abstract class _$SessionController extends $Notifier<SessionState> {
  SessionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SessionState, SessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionState, SessionState>,
              SessionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
