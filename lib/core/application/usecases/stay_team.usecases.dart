import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/services/stay.repository.dart';

/// Un séjour et sa direction.
class GetStayUseCase {
  final StayRepository _stays;

  GetStayUseCase(this._stays);

  Future<StayDetailDto> execute(String stayId) async =>
      StayDetailDto.fromDomain(await _stays.get(stayId));
}

/// Nomme le directeur ([StaffRole.director]) ou ajoute un adjoint
/// ([StaffRole.deputy]), désigné par son numéro de mobile en saisie libre.
/// Avec [firstName] et [lastName], un numéro sans compte en reçoit un.
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
    };
    return StayDetailDto.fromDomain(detail);
  }
}

/// Retire le directeur ou l'adjoint [accountId].
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
    };
    return StayDetailDto.fromDomain(detail);
  }
}

/// Les séjours où le compte connecté est directeur ou adjoint.
class ListMyStaysUseCase {
  final StayRepository _stays;

  ListMyStaysUseCase(this._stays);

  Future<List<MyStayDto>> execute() async =>
      (await _stays.mine()).map(MyStayDto.fromDomain).toList();
}
