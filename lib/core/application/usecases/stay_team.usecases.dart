import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/services/stay.repository.dart';

/// Un séjour et son équipe.
class GetStayUseCase {
  final StayRepository _stays;

  GetStayUseCase(this._stays);

  Future<StayDetailDto> execute(String stayId) async =>
      StayDetailDto.fromDomain(await _stays.get(stayId));
}

/// Ajoute un directeur, un adjoint ou un animateur selon [StaffRole], désigné
/// par son numéro de mobile en saisie libre. Avec [firstName] et [lastName], un
/// numéro sans compte en reçoit un ; avec `demote`, un membre de la direction
/// passe animateur.
class NameStaffUseCase {
  final StayRepository _stays;

  NameStaffUseCase(this._stays);

  /// Lève `StayException(invalidPhone | invalidPersonName)` avant tout appel
  /// si le numéro n'est pas un mobile français, ou si un nom donné est vide.
  Future<StayDetailDto> execute(
    String stayId,
    StaffRole role, {
    required String rawPhone,
    String? firstName,
    String? lastName,
    bool demote = false,
  }) async {
    final PhoneNumber phone;
    try {
      phone = PhoneNumber.parse(rawPhone);
    } on AuthException {
      throw const StayException(StayErrorCode.invalidPhone);
    }
    final newAccount = firstName == null && lastName == null
        ? null
        : NewStaffAccount.parse(
            firstName: firstName ?? '',
            lastName: lastName ?? '',
          );
    final detail = switch (role) {
      StaffRole.director => await _stays.nameDirector(
        stayId,
        phone,
        newAccount: newAccount,
      ),
      StaffRole.deputy => await _stays.addDeputy(
        stayId,
        phone,
        newAccount: newAccount,
      ),
      StaffRole.animator => await _stays.addAnimator(
        stayId,
        phone,
        newAccount: newAccount,
        demote: demote,
      ),
    };
    return StayDetailDto.fromDomain(detail);
  }
}

/// Retire le directeur, l'adjoint ou l'animateur [accountId].
class RemoveStaffUseCase {
  final StayRepository _stays;

  RemoveStaffUseCase(this._stays);

  Future<StayDetailDto> execute(
    String stayId,
    StaffRole role, {
    required String accountId,
  }) async {
    final detail = switch (role) {
      StaffRole.director => await _stays.removeDirector(stayId, accountId),
      StaffRole.deputy => await _stays.removeDeputy(stayId, accountId),
      StaffRole.animator => await _stays.removeAnimator(stayId, accountId),
    };
    return StayDetailDto.fromDomain(detail);
  }
}

/// Les séjours où le compte connecté a un rôle.
class ListMyStaysUseCase {
  final StayRepository _stays;

  ListMyStaysUseCase(this._stays);

  Future<List<MyStayDto>> execute() async =>
      (await _stays.mine()).map(MyStayDto.fromDomain).toList();
}
