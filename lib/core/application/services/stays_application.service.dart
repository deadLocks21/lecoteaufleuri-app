import 'package:lecoteaufleuri/core/application/usecases/stays.usecases.dart';

/// Les cas d'usage de l'administration des séjours, regroupés pour son
/// contrôleur.
class StaysApplicationService {
  final ListStaysUseCase list;
  final CreateStayUseCase create;

  const StaysApplicationService({required this.list, required this.create});
}
