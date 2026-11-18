import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';

/// Ce qu'un admin saisit pour créer un séjour, validé avant d'être envoyé avec
/// les mêmes règles que l'API : nom non vide (255 caractères au plus), nature
/// choisie, fin au plus tôt le jour du début.
class StayDraft {
  /// Longueur maximale du nom, celle de l'API.
  static const nameMaxLength = 255;

  final String name;
  final StayKind kind;
  final DateTime startsOn;
  final DateTime endsOn;

  const StayDraft._(this.name, this.kind, this.startsOn, this.endsOn);

  /// Lève `StayException(invalidName | invalidKind | invalidDates)`, dans cet
  /// ordre, celui du formulaire. Les dates sont ramenées à leur jour.
  factory StayDraft.parse({
    required String name,
    required StayKind? kind,
    required DateTime? startsOn,
    required DateTime? endsOn,
  }) {
    final trimmed = name.trim();
    // En caractères (points de code), comme l'API.
    if (trimmed.isEmpty || trimmed.runes.length > nameMaxLength) {
      throw const StayException(StayErrorCode.invalidName);
    }
    if (kind == null) {
      throw const StayException(StayErrorCode.invalidKind);
    }
    if (startsOn == null || endsOn == null) {
      throw const StayException(StayErrorCode.invalidDates);
    }
    final start = calendarDay(startsOn);
    final end = calendarDay(endsOn);
    if (end.isBefore(start)) {
      throw const StayException(StayErrorCode.invalidDates);
    }
    return StayDraft._(trimmed, kind, start, end);
  }
}
