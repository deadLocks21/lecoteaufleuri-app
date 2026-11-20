import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/application/stay_periods.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/services/last_stay.repository.dart';

/// Choisit, parmi les séjours du compte, celui où ouvrir l'app (cf.
/// [defaultStay]), d'après le dernier ouvert sur cet appareil.
class PickDefaultStayUseCase {
  final LastStayRepository _lastStay;

  PickDefaultStayUseCase(this._lastStay);

  Future<MyStayDto?> execute(
    String accountId,
    List<MyStayDto> stays, {
    DateTime? now,
  }) async => defaultStay(
    stays,
    lastOpenedId: await _lastStay.read(accountId),
    today: calendarDay(now ?? DateTime.now()),
  );
}

/// Retient le séjour que le compte vient d'ouvrir.
class RememberStayUseCase {
  final LastStayRepository _lastStay;

  RememberStayUseCase(this._lastStay);

  Future<void> execute(String accountId, String stayId) =>
      _lastStay.write(accountId, stayId);
}
