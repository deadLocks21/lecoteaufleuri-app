import 'package:flutter/foundation.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/application/services/stays_application.service.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/infrastructure/providers/my_stays.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_detail.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_space.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stays.service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stays.controller_provider.g.dart';

/// La liste des séjours de l'écran d'administration, leur création et leur
/// modification.
///
/// Libérée dès que l'écran se ferme (pas de `keepAlive`), comme les comptes :
/// rien ne survit à une déconnexion ou à un statut d'admin retiré.
///
/// [create] rend le séjour créé, ou l'[StayErrorCode] que l'écran traduit en
/// message ; la liste est relue après une création. [edit] fait de même, et
/// fait relire partout ailleurs le séjour modifié (accueil, espace du séjour).
@riverpod
class StaysController extends _$StaysController {
  StaysApplicationService get _service => ref.read(staysServiceProvider);

  @override
  Future<List<StayDto>> build() =>
      ref.watch(staysServiceProvider).list.execute();

  Future<(StayDto?, StayErrorCode?)> create({
    required String name,
    required StayKind? kind,
    required DateTime? startsOn,
    required DateTime? endsOn,
  }) async {
    try {
      final stay = await _service.create.execute(
        name: name,
        kind: kind,
        startsOn: startsOn,
        endsOn: endsOn,
      );
      if (ref.mounted) ref.invalidateSelf();
      return (stay, null);
    } on StayException catch (e) {
      return (null, e.code);
    } catch (e, stack) {
      debugPrint('séjours : échec inattendu : $e\n$stack');
      return (null, StayErrorCode.unknown);
    }
  }

  Future<(StayDto?, StayErrorCode?)> edit(
    String stayId, {
    required String name,
    required StayKind? kind,
    required DateTime? startsOn,
    required DateTime? endsOn,
  }) async {
    try {
      final stay = await _service.update.execute(
        stayId,
        name: name,
        kind: kind,
        startsOn: startsOn,
        endsOn: endsOn,
      );
      if (ref.mounted) {
        ref
          ..invalidate(myStaysProvider)
          ..invalidate(staySpaceProvider(stayId))
          ..invalidate(stayDetailControllerProvider(stayId))
          ..invalidateSelf();
      }
      return (stay, null);
    } on StayException catch (e) {
      return (null, e.code);
    } catch (e, stack) {
      debugPrint('séjours : échec inattendu : $e\n$stack');
      return (null, StayErrorCode.unknown);
    }
  }
}
