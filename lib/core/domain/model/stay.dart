/// La nature d'un séjour, qui décide de qui s'y inscrit (cf. `ACCES.md` du
/// dépôt lecoteaufleuri/dev).
enum StayKind {
  /// Accueil collectif de mineurs : des enfants, inscrits par leurs
  /// responsables.
  acm,

  /// Hors ACM : chaque participant est inscrit en son nom.
  other,
}

/// Un séjour de l'association.
///
/// [startsOn] et [endsOn] sont des jours du calendrier (premier et dernier,
/// compris), portés par des `DateTime` à minuit UTC : seuls l'année, le mois et
/// le jour comptent.
class Stay {
  final String id;
  final String name;
  final StayKind kind;
  final DateTime startsOn;
  final DateTime endsOn;

  Stay({
    required this.id,
    required this.name,
    required this.kind,
    required this.startsOn,
    required this.endsOn,
  }) : assert(id.isNotEmpty, 'id cannot be empty'),
       assert(!endsOn.isBefore(startsOn), 'a stay cannot end before it starts');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stay &&
          other.id == id &&
          other.name == name &&
          other.kind == kind &&
          other.startsOn == startsOn &&
          other.endsOn == endsOn;

  @override
  int get hashCode => Object.hash(id, name, kind, startsOn, endsOn);
}

/// Le jour de [date] (année, mois, jour), à minuit UTC.
DateTime calendarDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);
