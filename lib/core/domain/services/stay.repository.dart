import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';

/// Port d'administration des séjours, réservée aux admins (l'API le vérifie à
/// chaque appel). Tout échec est signalé par une `StayException`.
abstract interface class StayRepository {
  /// Tous les séjours, du dernier commencé (ou à venir) au plus ancien, puis
  /// par nom.
  Future<List<Stay>> list();

  Future<Stay> create(StayDraft draft);
}
