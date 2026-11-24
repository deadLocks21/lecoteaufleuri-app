// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_thread.controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Une question ouverte, avec son fil, et ce qu'on y fait. Chaque action
/// rend null, ou la raison de l'échec ; la liste des questions suit.

@ProviderFor(QuestionThreadController)
final questionThreadControllerProvider = QuestionThreadControllerFamily._();

/// Une question ouverte, avec son fil, et ce qu'on y fait. Chaque action
/// rend null, ou la raison de l'échec ; la liste des questions suit.
final class QuestionThreadControllerProvider
    extends $AsyncNotifierProvider<QuestionThreadController, QuestionDto> {
  /// Une question ouverte, avec son fil, et ce qu'on y fait. Chaque action
  /// rend null, ou la raison de l'échec ; la liste des questions suit.
  QuestionThreadControllerProvider._({
    required QuestionThreadControllerFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'questionThreadControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$questionThreadControllerHash();

  @override
  String toString() {
    return r'questionThreadControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  QuestionThreadController create() => QuestionThreadController();

  @override
  bool operator ==(Object other) {
    return other is QuestionThreadControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$questionThreadControllerHash() =>
    r'cd19bc9b4c5e4eaf84545091e65a9efab0b9f1ac';

/// Une question ouverte, avec son fil, et ce qu'on y fait. Chaque action
/// rend null, ou la raison de l'échec ; la liste des questions suit.

final class QuestionThreadControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          QuestionThreadController,
          AsyncValue<QuestionDto>,
          QuestionDto,
          FutureOr<QuestionDto>,
          (String, String)
        > {
  QuestionThreadControllerFamily._()
    : super(
        retry: null,
        name: r'questionThreadControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Une question ouverte, avec son fil, et ce qu'on y fait. Chaque action
  /// rend null, ou la raison de l'échec ; la liste des questions suit.

  QuestionThreadControllerProvider call(String stayId, String questionId) =>
      QuestionThreadControllerProvider._(
        argument: (stayId, questionId),
        from: this,
      );

  @override
  String toString() => r'questionThreadControllerProvider';
}

/// Une question ouverte, avec son fil, et ce qu'on y fait. Chaque action
/// rend null, ou la raison de l'échec ; la liste des questions suit.

abstract class _$QuestionThreadController extends $AsyncNotifier<QuestionDto> {
  late final _$args = ref.$arg as (String, String);
  String get stayId => _$args.$1;
  String get questionId => _$args.$2;

  FutureOr<QuestionDto> build(String stayId, String questionId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<QuestionDto>, QuestionDto>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<QuestionDto>, QuestionDto>,
              AsyncValue<QuestionDto>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
