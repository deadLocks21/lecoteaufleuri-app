import 'package:lecoteaufleuri/core/application/usecases/stay_team.usecases.dart';
import 'package:lecoteaufleuri/core/application/usecases/stays.usecases.dart';

/// Les cas d'usage des séjours, regroupés pour leurs contrôleurs :
/// l'administration (liste, création) et la direction d'un séjour.
class StaysApplicationService {
  final ListStaysUseCase list;
  final CreateStayUseCase create;
  final GetStayUseCase get;
  final NameStaffUseCase nameStaff;
  final RemoveStaffUseCase removeStaff;
  final ListMyStaysUseCase mine;

  const StaysApplicationService({
    required this.list,
    required this.create,
    required this.get,
    required this.nameStaff,
    required this.removeStaff,
    required this.mine,
  });
}
