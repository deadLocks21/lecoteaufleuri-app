import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stays.service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_stays.provider.g.dart';

/// Les séjours où le compte connecté est directeur ou adjoint, pour l'accueil.
///
/// Sans `keepAlive` : libéré avec l'accueil, donc à la déconnexion. L'accueil
/// le relit quand les droits du compte sont relus.
@riverpod
Future<List<MyStayDto>> myStays(Ref ref) =>
    ref.watch(staysServiceProvider).mine.execute();
