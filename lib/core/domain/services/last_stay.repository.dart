/// Le dernier séjour ouvert sur cet appareil, par compte : l'app y revient au
/// lancement suivant.
abstract interface class LastStayRepository {
  /// L'identifiant du dernier séjour ouvert par [accountId], ou `null`.
  Future<String?> read(String accountId);

  Future<void> write(String accountId, String stayId);
}
