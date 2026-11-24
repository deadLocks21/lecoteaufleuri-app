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

  /// Le nom, la nature et les dates du séjour [stayId]. Un séjour qui a une
  /// équipe reste ACM (`hasTeam`), et ses nouvelles dates gardent ses jours
  /// des nouvelles et ses événements du calendrier (`entriesOutsideDates`).
  /// Admins seulement.
  Future<Stay> update(String stayId, StayDraft draft);

  /// Le séjour et son équipe : admin, directeurs et adjoints du séjour.
  Future<StayDetail> get(String stayId);

  /// Le compte de [phone] rejoint les directeurs. S'il n'existe pas,
  /// [newAccount] le crée ; sans lui, `unknownPhone`. Admins seulement.
  Future<StayDetail> nameDirector(
    String stayId,
    PhoneNumber phone, {
    NewStaffAccount? newAccount,
  });

  /// Le directeur [accountId] quitte la direction. Admins seulement.
  Future<StayDetail> removeDirector(String stayId, String accountId);

  /// Le compte de [phone] devient adjoint ; comme [nameDirector] pour un
  /// numéro sans compte. Admin et directeur du séjour.
  Future<StayDetail> addDeputy(
    String stayId,
    PhoneNumber phone, {
    NewStaffAccount? newAccount,
  });

  /// Admin et directeur du séjour.
  Future<StayDetail> removeDeputy(String stayId, String accountId);

  /// Le compte de [phone] devient animateur ; comme [nameDirector] pour un
  /// numéro sans compte. Un directeur ou un adjoint du séjour n'est rétrogradé
  /// qu'avec [demote] : sans lui, `alreadyDirector` ou `alreadyDeputy`. Admin,
  /// directeurs et adjoints du séjour.
  Future<StayDetail> addAnimator(
    String stayId,
    PhoneNumber phone, {
    NewStaffAccount? newAccount,
    bool demote = false,
  });

  /// Admin, directeurs et adjoints du séjour.
  Future<StayDetail> removeAnimator(String stayId, String accountId);

  /// Les séjours où le compte connecté a un rôle (directeur, adjoint,
  /// animateur).
  Future<List<MyStay>> mine();
}
