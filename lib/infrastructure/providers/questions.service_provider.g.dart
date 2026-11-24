// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'questions.service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(questionsService)
final questionsServiceProvider = QuestionsServiceProvider._();

final class QuestionsServiceProvider
    extends
        $FunctionalProvider<
          QuestionsApplicationService,
          QuestionsApplicationService,
          QuestionsApplicationService
        >
    with $Provider<QuestionsApplicationService> {
  QuestionsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questionsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questionsServiceHash();

  @$internal
  @override
  $ProviderElement<QuestionsApplicationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  QuestionsApplicationService create(Ref ref) {
    return questionsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuestionsApplicationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuestionsApplicationService>(value),
    );
  }
}

String _$questionsServiceHash() => r'87b5c6cbdd50e8c45c58fd5405ca5e643649c6a0';
