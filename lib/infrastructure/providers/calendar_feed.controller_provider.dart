import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/calendar.service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_feed.controller_provider.g.dart';

/// Le lien d'abonnement du compte au calendrier d'un séjour, et de quoi le
/// régénérer. Libéré avec la feuille qui l'affiche.
@riverpod
class CalendarFeedController extends _$CalendarFeedController {
  @override
  Future<CalendarFeedDto> build(String stayId) =>
      ref.watch(calendarServiceProvider).feed.execute(stayId);

  /// Null si le nouveau lien est là, la raison de l'échec sinon.
  Future<CalendarErrorCode?> renew() async {
    try {
      final feed = await ref.read(calendarServiceProvider).feed.renew(stayId);
      if (ref.mounted) state = AsyncData(feed);
      return null;
    } on CalendarException catch (e) {
      return e.code;
    }
  }
}
