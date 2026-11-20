import 'package:lecoteaufleuri/ui/pages/stays/stay_modules.dart';

/// Les adresses de l'app. Sur le web elles s'affichent dans la barre
/// d'adresse : un lien ouvre directement un séjour ou l'un de ses modules.
abstract final class AppRoutes {
  static const start = '/';
  static const loading = '/chargement';
  static const login = '/connexion';
  static const otp = '/code';

  static String stay(String stayId) => '/sejours/$stayId';
  static String stayModule(String stayId, StayModule module) =>
      '/sejours/$stayId/${module.path}';

  static const admin = '/admin';
  static const adminStays = '/admin/sejours';
  static const adminAccounts = '/admin/comptes';

  /// Les étapes de connexion, hors du cadre de l'app.
  static const auth = {loading, login, otp};
}

/// L'espace d'une adresse : un séjour (et l'un de ses modules), ou
/// l'administration (et l'une de ses pages).
sealed class SpaceLocation {
  const SpaceLocation();

  /// `null` hors de tout espace (le démarrage, l'accueil vide).
  static SpaceLocation? parse(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return switch (segments) {
      ['sejours', final id, ...final rest] => StayLocation(
        id,
        rest.isEmpty
            ? null
            : StayModule.values.where((m) => m.path == rest.first).firstOrNull,
      ),
      ['admin', ...final rest] => AdminLocation(
        rest.isEmpty ? null : AdminSection.fromPath(rest.first),
      ),
      _ => null,
    };
  }
}

class StayLocation extends SpaceLocation {
  final String stayId;

  /// `null` sur la vue d'ensemble du séjour.
  final StayModule? module;

  const StayLocation(this.stayId, this.module);
}

class AdminLocation extends SpaceLocation {
  /// `null` sur la vue d'ensemble de l'administration.
  final AdminSection? section;

  const AdminLocation(this.section);
}

/// Les pages de l'administration.
enum AdminSection {
  stays(AppRoutes.adminStays, 'sejours'),
  accounts(AppRoutes.adminAccounts, 'comptes');

  final String location;
  final String path;

  const AdminSection(this.location, this.path);

  static AdminSection? fromPath(String path) =>
      values.where((s) => s.path == path).firstOrNull;
}
