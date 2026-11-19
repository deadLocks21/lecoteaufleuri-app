import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';

/// Port des séjours. L'API vérifie chaque droit à chaque appel (admin,
/// directeur, adjoint) ; tout échec est signalé par une `StayException`.
abstract interface class StayRepository {
  /// Tous les séjours, du dernier commencé (ou à venir) au plus ancien, puis
  /// par nom. Admins seulement.
  Future<List<Stay>> list();

  /// Admins seulement.
  Future<Stay> create(StayDraft draft);

  /// Le séjour et sa direction : admin, directeur et adjoints du séjour.
  Future<StayDetail> get(String stayId);

  /// Ce compte devient directeur, à la place du précédent. Admins seulement.
  Future<StayDetail> nameDirector(String stayId, PhoneNumber phone);

  /// Admins seulement.
  Future<StayDetail> removeDirector(String stayId);

  /// Admin et directeur du séjour.
  Future<StayDetail> addDeputy(String stayId, PhoneNumber phone);

  /// Admin et directeur du séjour.
  Future<StayDetail> removeDeputy(String stayId, String accountId);

  /// Les séjours où le compte connecté est directeur ou adjoint.
  Future<List<MyStay>> mine();
}
