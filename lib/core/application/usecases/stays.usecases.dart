import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
import 'package:lecoteaufleuri/core/domain/services/stay.repository.dart';

/// Tous les séjours, pour l'écran d'administration.
class ListStaysUseCase {
  final StayRepository _stays;

  ListStaysUseCase(this._stays);

  Future<List<StayDto>> execute() async =>
      (await _stays.list()).map(StayDto.fromDomain).toList();
}

/// Crée un séjour à partir de la saisie : nom obligatoire, nature choisie,
/// fin au plus tôt le jour du début.
class CreateStayUseCase {
  final StayRepository _stays;

  CreateStayUseCase(this._stays);

  Future<StayDto> execute({
    required String name,
    required StayKind? kind,
    required DateTime? startsOn,
    required DateTime? endsOn,
  }) async {
    final draft = StayDraft.parse(
      name: name,
      kind: kind,
      startsOn: startsOn,
      endsOn: endsOn,
    );
    return StayDto.fromDomain(await _stays.create(draft));
  }
}

/// Modifie un séjour, saisie vérifiée comme à la création.
class UpdateStayUseCase {
  final StayRepository _stays;

  UpdateStayUseCase(this._stays);

  Future<StayDto> execute(
    String stayId, {
    required String name,
    required StayKind? kind,
    required DateTime? startsOn,
    required DateTime? endsOn,
  }) async {
    final draft = StayDraft.parse(
      name: name,
      kind: kind,
      startsOn: startsOn,
      endsOn: endsOn,
    );
    return StayDto.fromDomain(await _stays.update(stayId, draft));
  }
}
