import 'package:lecoteaufleuri/core/domain/model/stay.dart';

/// Un séjour, tel que l'administration l'affiche. [startsOn] et [endsOn] sont
/// des jours (minuit UTC), bornes comprises.
class StayDto {
  final String id;
  final String name;
  final StayKind kind;
  final DateTime startsOn;
  final DateTime endsOn;

  const StayDto({
    required this.id,
    required this.name,
    required this.kind,
    required this.startsOn,
    required this.endsOn,
  });

  factory StayDto.fromDomain(Stay stay) => StayDto(
    id: stay.id,
    name: stay.name,
    kind: stay.kind,
    startsOn: stay.startsOn,
    endsOn: stay.endsOn,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StayDto &&
          other.id == id &&
          other.name == name &&
          other.kind == kind &&
          other.startsOn == startsOn &&
          other.endsOn == endsOn;

  @override
  int get hashCode => Object.hash(id, name, kind, startsOn, endsOn);
}
