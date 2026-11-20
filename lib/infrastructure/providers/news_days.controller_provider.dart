import 'package:flutter/foundation.dart';
import 'package:lecoteaufleuri/core/application/dtos/news.dto.dart';
import 'package:lecoteaufleuri/core/application/services/news_application.service.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/news.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/news.service_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_news.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_photos.controller_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'news_days.controller_provider.g.dart';

/// Le résultat d'une action sur un jour : le jour rendu par l'API, ou la
/// raison de l'échec.
typedef DayResult = ({NewsDayDto? day, NewsErrorCode? error});

/// Les jours d'un séjour, tels que la direction les compose, et ce qu'on peut
/// y faire : créer, corriger, illustrer, publier, programmer, dépublier,
/// supprimer.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).
/// Chaque action relit aussi ce qu'elle change ailleurs : le jour illustré par
/// chaque photo (la pioche) et les nouvelles publiées.
@riverpod
class NewsDaysController extends _$NewsDaysController {
  NewsApplicationService get _service => ref.read(newsServiceProvider);

  @override
  Future<List<NewsDayDto>> build(String stayId) =>
      ref.watch(newsServiceProvider).days.execute(stayId);

  Future<DayResult> create(DateTime date) =>
      _run(() => _service.createDay.execute(stayId, date));

  Future<DayResult> edit(
    String dayId, {
    required DateTime date,
    required String summary,
  }) => _run(
    () =>
        _service.updateDay.execute(stayId, dayId, date: date, summary: summary),
  );

  Future<DayResult> setPhotos(String dayId, List<String> photoIds) =>
      _run(() => _service.setDayPhotos.execute(stayId, dayId, photoIds));

  /// Tout de suite sans [at], programmé sinon.
  Future<DayResult> publish(String dayId, {DateTime? at}) =>
      _run(() => _service.publishDay.execute(stayId, dayId, at: at));

  Future<DayResult> unpublish(String dayId) =>
      _run(() => _service.unpublishDay.execute(stayId, dayId));

  Future<NewsErrorCode?> delete(String dayId) async {
    final result = await _run(() async {
      await _service.deleteDay.execute(stayId, dayId);
      return null;
    }, removed: dayId);
    return result.error;
  }

  Future<DayResult> _run(
    Future<NewsDayDto?> Function() action, {
    String? removed,
  }) async {
    try {
      final day = await action();
      if (ref.mounted) {
        final days = [
          for (final other in state.value ?? const <NewsDayDto>[])
            if (other.id != day?.id && other.id != removed) other,
          ?day,
        ]..sort((a, b) => a.date.compareTo(b.date));
        state = AsyncData(days);
        ref
          ..invalidate(stayPhotosControllerProvider(stayId))
          ..invalidate(stayNewsProvider(stayId));
      }
      return (day: day, error: null);
    } on NewsException catch (e) {
      // Jour disparu, ou droits retirés : on relit ce qu'on peut encore voir.
      if (const {
            NewsErrorCode.dayNotFound,
            NewsErrorCode.stayNotFound,
            NewsErrorCode.forbidden,
          }.contains(e.code) &&
          ref.mounted) {
        ref.invalidateSelf();
      }
      return (day: null, error: e.code);
    } catch (e, stack) {
      debugPrint('jours : échec inattendu : $e\n$stack');
      return (day: null, error: NewsErrorCode.unknown);
    }
  }
}
