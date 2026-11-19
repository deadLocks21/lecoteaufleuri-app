import 'package:lecoteaufleuri/core/application/services/stays_application.service.dart';
import 'package:lecoteaufleuri/core/application/usecases/stay_team.usecases.dart';
import 'package:lecoteaufleuri/core/application/usecases/stays.usecases.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay.repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stays.service_provider.g.dart';

@Riverpod(keepAlive: true)
StaysApplicationService staysService(Ref ref) {
  final stays = ref.watch(stayRepositoryProvider);
  return StaysApplicationService(
    list: ListStaysUseCase(stays),
    create: CreateStayUseCase(stays),
    get: GetStayUseCase(stays),
    nameStaff: NameStaffUseCase(stays),
    removeStaff: RemoveStaffUseCase(stays),
    mine: ListMyStaysUseCase(stays),
  );
}
