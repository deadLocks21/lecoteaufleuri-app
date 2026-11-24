import 'package:lecoteaufleuri/core/application/services/stays_application.service.dart';
import 'package:lecoteaufleuri/core/application/usecases/last_stay.usecases.dart';
import 'package:lecoteaufleuri/core/application/usecases/stay_team.usecases.dart';
import 'package:lecoteaufleuri/core/application/usecases/stays.usecases.dart';
import 'package:lecoteaufleuri/infrastructure/providers/last_stay.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay.repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stays.service_provider.g.dart';

@Riverpod(keepAlive: true)
StaysApplicationService staysService(Ref ref) {
  final stays = ref.watch(stayRepositoryProvider);
  final lastStay = ref.watch(lastStayRepositoryProvider);
  return StaysApplicationService(
    list: ListStaysUseCase(stays),
    create: CreateStayUseCase(stays),
    update: UpdateStayUseCase(stays),
    get: GetStayUseCase(stays),
    nameStaff: NameStaffUseCase(stays),
    removeStaff: RemoveStaffUseCase(stays),
    mine: ListMyStaysUseCase(stays),
    pickDefault: PickDefaultStayUseCase(lastStay),
    remember: RememberStayUseCase(lastStay),
  );
}
