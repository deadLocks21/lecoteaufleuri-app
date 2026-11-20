import 'package:lecoteaufleuri/core/domain/services/last_stay.repository.dart';
import 'package:lecoteaufleuri/infrastructure/stays/shared_preferences.last_stay.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'last_stay.repository_provider.g.dart';

@Riverpod(keepAlive: true)
LastStayRepository lastStayRepository(Ref ref) =>
    SharedPreferencesLastStayRepository();
