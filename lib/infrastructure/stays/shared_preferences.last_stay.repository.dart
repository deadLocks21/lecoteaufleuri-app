import 'package:flutter/foundation.dart';
import 'package:lecoteaufleuri/core/domain/services/last_stay.repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dernier séjour ouvert, rangé dans `shared_preferences` par compte : deux
/// comptes sur le même appareil ne se le partagent pas.
///
/// Ce n'est qu'une commodité : un stockage indisponible vaut « aucun séjour
/// mémorisé », et l'app choisit alors d'après les dates.
class SharedPreferencesLastStayRepository implements LastStayRepository {
  static String _key(String accountId) => 'lecoteaufleuri.lastStay.$accountId';

  @override
  Future<String?> read(String accountId) async {
    try {
      return (await SharedPreferences.getInstance()).getString(_key(accountId));
    } catch (e) {
      debugPrint('dernier séjour : lecture impossible : $e');
      return null;
    }
  }

  @override
  Future<void> write(String accountId, String stayId) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _key(accountId),
        stayId,
      );
    } catch (e) {
      debugPrint('dernier séjour : écriture impossible : $e');
    }
  }
}
