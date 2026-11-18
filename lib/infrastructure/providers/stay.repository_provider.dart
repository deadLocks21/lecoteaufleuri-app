import 'package:lecoteaufleuri/core/domain/services/stay.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/api_base_url.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/dio.provider.dart';
import 'package:lecoteaufleuri/infrastructure/stays/dio.stay.repository.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.stay.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stay.repository_provider.g.dart';

/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, séjours de démo en
/// mémoire sinon.
@Riverpod(keepAlive: true)
StayRepository stayRepository(Ref ref) {
  if (isInMemoryMode(ref.watch(apiBaseUrlProvider))) {
    return InMemoryStayRepository();
  }
  return DioStayRepository(ref.watch(dioProvider));
}
