import 'package:lecoteaufleuri/core/application/dtos/news.dto.dart';
import 'package:lecoteaufleuri/infrastructure/providers/news.service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stay_news.provider.g.dart';

/// Les jours publiés d'un séjour, du plus récent au plus ancien : ce que
/// liront les familles. Libéré avec l'écran qui l'affiche.
@riverpod
Future<List<PublishedDayDto>> stayNews(Ref ref, String stayId) =>
    ref.watch(newsServiceProvider).news.execute(stayId);
