import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';

/// Forme JSON d'un séjour, celle de l'API : jours au format `AAAA-MM-JJ`,
/// nature `acm` ou `other`.
abstract final class StayCodec {
  static final _day = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Lève une [FormatException] si [json] n'a pas la forme attendue.
  static Stay fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'kind': final String kind,
      'starts_on': final String startsOn,
      'ends_on': final String endsOn,
    } when id.isNotEmpty) {
      final start = parseDay(startsOn);
      final end = parseDay(endsOn);
      if (end.isBefore(start)) {
        throw const FormatException('Stay JSON ends before it starts');
      }
      return Stay(
        id: id,
        name: name,
        kind: switch (kind) {
          'acm' => StayKind.acm,
          'other' => StayKind.other,
          _ => throw const FormatException('Stay JSON has an unknown kind'),
        },
        startsOn: start,
        endsOn: end,
      );
    }
    throw const FormatException('Stay JSON is malformed');
  }

  /// Un séjour avec son équipe (`GET /api/stays/{id}` et ses actions).
  static StayDetail detailFromJson(Object? json) {
    if (json case {
      'directors': final List<Object?> directors,
      'deputies': final List<Object?> deputies,
      'animators': final List<Object?> animators,
      'can_manage_directors': final bool canManageDirectors,
      'can_manage_deputies': final bool canManageDeputies,
      'can_manage_animators': final bool canManageAnimators,
    }) {
      return StayDetail(
        stay: fromJson(json),
        directors: [for (final director in directors) _member(director)],
        deputies: [for (final deputy in deputies) _member(deputy)],
        animators: [for (final animator in animators) _member(animator)],
        canManageDirectors: canManageDirectors,
        canManageDeputies: canManageDeputies,
        canManageAnimators: canManageAnimators,
      );
    }
    throw const FormatException('Stay detail JSON is malformed');
  }

  /// Un séjour du compte connecté, avec son rôle (`GET /api/me/stays`).
  static MyStay myStayFromJson(Object? json) {
    if (json case {'role': final String role}) {
      return MyStay(
        stay: fromJson(json),
        role: switch (role) {
          'director' => StaffRole.director,
          'deputy' => StaffRole.deputy,
          'animator' => StaffRole.animator,
          _ => throw const FormatException('Unknown staff role'),
        },
      );
    }
    throw const FormatException('My stay JSON is malformed');
  }

  static TeamMember _member(Object? json) {
    if (json case {
      'id': final String id,
      'first_name': final String firstName,
      'last_name': final String lastName,
    } when id.isNotEmpty) {
      return TeamMember(id: id, firstName: firstName, lastName: lastName);
    }
    throw const FormatException('Team member JSON is malformed');
  }

  static Map<String, dynamic> toJson(StayDraft draft) => {
    'name': draft.name,
    'kind': draft.kind.name,
    'starts_on': formatDay(draft.startsOn),
    'ends_on': formatDay(draft.endsOn),
  };

  /// `AAAA-MM-JJ` → le jour, à minuit UTC. Lève une [FormatException] pour
  /// toute autre forme, ou un jour qui n'existe pas.
  static DateTime parseDay(String value) {
    final match = _day.firstMatch(value);
    if (match != null) {
      final [year, month, day] = [
        for (final group in [1, 2, 3]) int.parse(match.group(group)!),
      ];
      final date = DateTime.utc(year, month, day);
      if (date.year == year && date.month == month && date.day == day) {
        return date;
      }
    }
    throw FormatException('Not a YYYY-MM-DD day', value);
  }

  static String formatDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
