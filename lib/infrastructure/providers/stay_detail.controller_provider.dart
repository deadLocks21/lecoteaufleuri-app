import 'package:flutter/foundation.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/application/services/stays_application.service.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/infrastructure/providers/my_stays.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stays.service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stay_detail.controller_provider.g.dart';

/// Un séjour et sa direction, et ce qu'on peut y changer (directeur,
/// adjoints).
///
/// Libéré dès que l'écran se ferme (pas de `keepAlive`). Les actions rendent
/// `null` en cas de succès, sinon l'[StayErrorCode] que l'écran traduit ; le
/// séjour rendu par l'API remplace l'état.
@riverpod
class StayDetailController extends _$StayDetailController {
  StaysApplicationService get _service => ref.read(staysServiceProvider);

  @override
  Future<StayDetailDto> build(String stayId) =>
      ref.watch(staysServiceProvider).get.execute(stayId);

  /// Avec [firstName] et [lastName], un numéro sans compte en reçoit un.
  Future<StayErrorCode?> name(
    StaffRole role, {
    required String rawPhone,
    String? firstName,
    String? lastName,
  }) => _run(
    () => _service.nameStaff.execute(
      stayId,
      role,
      rawPhone: rawPhone,
      firstName: firstName,
      lastName: lastName,
    ),
  );

  Future<StayErrorCode?> remove(StaffRole role, {String? accountId}) => _run(
    () => _service.removeStaff.execute(stayId, role, accountId: accountId),
  );

  Future<StayErrorCode?> _run(Future<StayDetailDto> Function() action) async {
    try {
      final detail = await action();
      if (ref.mounted) {
        state = AsyncData(detail);
        // Ses propres rôles ont pu changer : l'accueil les relira.
        ref.invalidate(myStaysProvider);
      }
      return null;
    } on StayException catch (e) {
      // Séjour disparu, ou droits retirés : on relit ce qu'on peut encore voir.
      if ((e.code == StayErrorCode.notFound ||
              e.code == StayErrorCode.forbidden) &&
          ref.mounted) {
        ref.invalidateSelf();
      }
      return e.code;
    } catch (e, stack) {
      debugPrint('séjour : échec inattendu : $e\n$stack');
      return StayErrorCode.unknown;
    }
  }
}
