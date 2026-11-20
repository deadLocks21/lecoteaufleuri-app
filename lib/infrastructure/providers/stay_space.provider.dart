import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/infrastructure/providers/my_stays.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stays.service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stay_space.provider.g.dart';

/// Le séjour ouvert, et le rôle qu'y tient le compte connecté.
///
/// Un séjour de « Mes séjours » s'ouvre avec son rôle ; un autre (un admin
/// qui l'a choisi dans la liste de l'association) se lit auprès de l'API, qui
/// refuse à qui n'y a pas droit. Sans `keepAlive`, comme [myStays].
@riverpod
Future<StaySpaceDto> staySpace(Ref ref, String stayId) async {
  List<MyStayDto> mine;
  try {
    mine = await ref.watch(myStaysProvider.future);
  } catch (_) {
    // « Mes séjours » illisible : la fiche du séjour peut encore répondre.
    mine = const [];
  }
  for (final stay in mine) {
    if (stay.stay.id == stayId) {
      return StaySpaceDto(stay: stay.stay, role: stay.role);
    }
  }
  final detail = await ref.watch(staysServiceProvider).get.execute(stayId);
  return StaySpaceDto(stay: detail.stay);
}
