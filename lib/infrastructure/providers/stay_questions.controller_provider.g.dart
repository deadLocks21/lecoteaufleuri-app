// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stay_questions.controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Les questions d'un séjour, sans leur fil (toutes pour la direction, les
/// publiques et les siennes pour un animateur), la plus récemment active
/// d'abord ; et poser une question.

@ProviderFor(StayQuestionsController)
final stayQuestionsControllerProvider = StayQuestionsControllerFamily._();

/// Les questions d'un séjour, sans leur fil (toutes pour la direction, les
/// publiques et les siennes pour un animateur), la plus récemment active
/// d'abord ; et poser une question.
final class StayQuestionsControllerProvider
    extends $AsyncNotifierProvider<StayQuestionsController, List<QuestionDto>> {
  /// Les questions d'un séjour, sans leur fil (toutes pour la direction, les
  /// publiques et les siennes pour un animateur), la plus récemment active
  /// d'abord ; et poser une question.
  StayQuestionsControllerProvider._({
    required StayQuestionsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stayQuestionsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stayQuestionsControllerHash();

  @override
  String toString() {
    return r'stayQuestionsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  StayQuestionsController create() => StayQuestionsController();

  @override
  bool operator ==(Object other) {
    return other is StayQuestionsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stayQuestionsControllerHash() =>
    r'841b536e26ee3b3c7e5d9d51b748e3743729ee64';

/// Les questions d'un séjour, sans leur fil (toutes pour la direction, les
/// publiques et les siennes pour un animateur), la plus récemment active
/// d'abord ; et poser une question.

final class StayQuestionsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          StayQuestionsController,
          AsyncValue<List<QuestionDto>>,
          List<QuestionDto>,
          FutureOr<List<QuestionDto>>,
          String
        > {
  StayQuestionsControllerFamily._()
    : super(
        retry: null,
        name: r'stayQuestionsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Les questions d'un séjour, sans leur fil (toutes pour la direction, les
  /// publiques et les siennes pour un animateur), la plus récemment active
  /// d'abord ; et poser une question.

  StayQuestionsControllerProvider call(String stayId) =>
      StayQuestionsControllerProvider._(argument: stayId, from: this);

  @override
  String toString() => r'stayQuestionsControllerProvider';
}

/// Les questions d'un séjour, sans leur fil (toutes pour la direction, les
/// publiques et les siennes pour un animateur), la plus récemment active
/// d'abord ; et poser une question.

abstract class _$StayQuestionsController
    extends $AsyncNotifier<List<QuestionDto>> {
  late final _$args = ref.$arg as String;
  String get stayId => _$args;

  FutureOr<List<QuestionDto>> build(String stayId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<QuestionDto>>, List<QuestionDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<QuestionDto>>, List<QuestionDto>>,
              AsyncValue<List<QuestionDto>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Les questions supprimées du séjour, que la direction restaure ou efface.

@ProviderFor(deletedQuestions)
final deletedQuestionsProvider = DeletedQuestionsFamily._();

/// Les questions supprimées du séjour, que la direction restaure ou efface.

final class DeletedQuestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<QuestionDto>>,
          List<QuestionDto>,
          FutureOr<List<QuestionDto>>
        >
    with
        $FutureModifier<List<QuestionDto>>,
        $FutureProvider<List<QuestionDto>> {
  /// Les questions supprimées du séjour, que la direction restaure ou efface.
  DeletedQuestionsProvider._({
    required DeletedQuestionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'deletedQuestionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deletedQuestionsHash();

  @override
  String toString() {
    return r'deletedQuestionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<QuestionDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<QuestionDto>> create(Ref ref) {
    final argument = this.argument as String;
    return deletedQuestions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DeletedQuestionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deletedQuestionsHash() => r'1ff4f3ee40a415b9eae15e075624460731c1e823';

/// Les questions supprimées du séjour, que la direction restaure ou efface.

final class DeletedQuestionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<QuestionDto>>, String> {
  DeletedQuestionsFamily._()
    : super(
        retry: null,
        name: r'deletedQuestionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Les questions supprimées du séjour, que la direction restaure ou efface.

  DeletedQuestionsProvider call(String stayId) =>
      DeletedQuestionsProvider._(argument: stayId, from: this);

  @override
  String toString() => r'deletedQuestionsProvider';
}

/// Les catégories du séjour, par ordre alphabétique ; la direction les crée
/// à la volée, les renomme et les supprime.

@ProviderFor(QuestionCategoriesController)
final questionCategoriesControllerProvider =
    QuestionCategoriesControllerFamily._();

/// Les catégories du séjour, par ordre alphabétique ; la direction les crée
/// à la volée, les renomme et les supprime.
final class QuestionCategoriesControllerProvider
    extends
        $AsyncNotifierProvider<
          QuestionCategoriesController,
          List<QuestionCategoryDto>
        > {
  /// Les catégories du séjour, par ordre alphabétique ; la direction les crée
  /// à la volée, les renomme et les supprime.
  QuestionCategoriesControllerProvider._({
    required QuestionCategoriesControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'questionCategoriesControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$questionCategoriesControllerHash();

  @override
  String toString() {
    return r'questionCategoriesControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  QuestionCategoriesController create() => QuestionCategoriesController();

  @override
  bool operator ==(Object other) {
    return other is QuestionCategoriesControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$questionCategoriesControllerHash() =>
    r'54e8a42eb1663a0d7d5fb977dc4967ca8c9c3da9';

/// Les catégories du séjour, par ordre alphabétique ; la direction les crée
/// à la volée, les renomme et les supprime.

final class QuestionCategoriesControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          QuestionCategoriesController,
          AsyncValue<List<QuestionCategoryDto>>,
          List<QuestionCategoryDto>,
          FutureOr<List<QuestionCategoryDto>>,
          String
        > {
  QuestionCategoriesControllerFamily._()
    : super(
        retry: null,
        name: r'questionCategoriesControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Les catégories du séjour, par ordre alphabétique ; la direction les crée
  /// à la volée, les renomme et les supprime.

  QuestionCategoriesControllerProvider call(String stayId) =>
      QuestionCategoriesControllerProvider._(argument: stayId, from: this);

  @override
  String toString() => r'questionCategoriesControllerProvider';
}

/// Les catégories du séjour, par ordre alphabétique ; la direction les crée
/// à la volée, les renomme et les supprime.

abstract class _$QuestionCategoriesController
    extends $AsyncNotifier<List<QuestionCategoryDto>> {
  late final _$args = ref.$arg as String;
  String get stayId => _$args;

  FutureOr<List<QuestionCategoryDto>> build(String stayId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<QuestionCategoryDto>>,
              List<QuestionCategoryDto>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<QuestionCategoryDto>>,
                List<QuestionCategoryDto>
              >,
              AsyncValue<List<QuestionCategoryDto>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
