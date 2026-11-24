import 'package:lecoteaufleuri/core/application/usecases/last_stay.usecases.dart';
import 'package:lecoteaufleuri/core/application/usecases/stay_team.usecases.dart';
import 'package:lecoteaufleuri/core/application/usecases/stays.usecases.dart';

/// Les cas d'usage des séjours, regroupés pour leurs contrôleurs :
/// l'administration (liste, création, modification), la direction d'un séjour, et le
/// séjour où ouvrir l'app.
class StaysApplicationService {
  final ListStaysUseCase list;
  final CreateStayUseCase create;
  final UpdateStayUseCase update;
  final GetStayUseCase get;
  final NameStaffUseCase nameStaff;
  final RemoveStaffUseCase removeStaff;
  final ListMyStaysUseCase mine;
  final PickDefaultStayUseCase pickDefault;
  final RememberStayUseCase remember;

  const StaysApplicationService({
    required this.list,
    required this.create,
    required this.update,
    required this.get,
    required this.nameStaff,
    required this.removeStaff,
    required this.mine,
    required this.pickDefault,
    required this.remember,
  });
}
