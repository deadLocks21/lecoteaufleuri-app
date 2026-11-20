import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/admin/accounts.page.dart';
import 'package:lecoteaufleuri/ui/pages/admin/admin.page.dart';
import 'package:lecoteaufleuri/ui/pages/admin/stays.page.dart';
import 'package:lecoteaufleuri/ui/pages/auth/otp_verify.page.dart';
import 'package:lecoteaufleuri/ui/pages/auth/phone_entry.page.dart';
import 'package:lecoteaufleuri/ui/pages/news/stay_news.page.dart';
import 'package:lecoteaufleuri/ui/pages/start/start.page.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay_modules.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay_overview.page.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay_team.page.dart';
import 'package:lecoteaufleuri/ui/router/app_routes.dart';
import 'package:lecoteaufleuri/ui/shell/app_shell.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.provider.g.dart';

/// Le routeur de l'app : l'adresse suit la [SessionState].
///
/// - Tant que la session se relit, l'app attend sur `/chargement`, puis
///   reprend l'adresse demandée (un lien vers un séjour, sur le web).
/// - Sans session, la connexion ; une session fermée referme donc tout ce qui
///   était ouvert, et ses données (providers sans `keepAlive`) avec.
/// - L'administration est réservée aux admins ; perdre ce statut ramène au
///   séjour du moment, quel que soit l'écran ouvert.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final session = ValueNotifier<SessionState>(
    ref.read(sessionControllerProvider),
  );
  ref.onDispose(session.dispose);

  late final GoRouter router;
  ref.listen(sessionControllerProvider, (previous, next) {
    final wasAdmin = previous is Authenticated && previous.session.user.isAdmin;
    final isAdmin = next is Authenticated && next.session.user.isAdmin;
    session.value = next;
    if (wasAdmin && !isAdmin && next is Authenticated) {
      router.go(AppRoutes.start);
    }
  });

  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.matchedLocation;
    return switch (session.value) {
      SessionRestoring() =>
        path == AppRoutes.loading
            ? null
            : Uri(
                path: AppRoutes.loading,
                queryParameters: {'from': state.uri.toString()},
              ).toString(),
      Anonymous() => path == AppRoutes.login ? null : AppRoutes.login,
      OtpRequested() => path == AppRoutes.otp ? null : AppRoutes.otp,
      Authenticated(:final session) =>
        AppRoutes.auth.contains(path)
            ? _resume(state.uri.queryParameters['from'])
            : path.startsWith(AppRoutes.admin) && !session.user.isAdmin
            ? AppRoutes.start
            : null,
    };
  }

  router = GoRouter(
    initialLocation: AppRoutes.start,
    refreshListenable: session,
    redirect: redirect,
    routes: [
      // La connexion change d'étape avec la session, sans animation : ce
      // n'est pas une navigation.
      GoRoute(
        path: AppRoutes.loading,
        pageBuilder: (_, state) => NoTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const PhoneEntryPage()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const OtpVerifyPage()),
      ),
      ShellRoute(
        // Le cadre apparaît sans animation après la connexion.
        pageBuilder: (_, state, child) => NoTransitionPage(
          key: state.pageKey,
          child: AppShell(location: state.uri, child: child),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.start,
            pageBuilder: (_, state) =>
                NoTransitionPage(key: state.pageKey, child: const StartPage()),
          ),
          GoRoute(
            path: '/sejours/:stayId',
            pageBuilder: (context, state) => _page(
              context,
              state,
              StayOverviewPage(stayId: state.pathParameters['stayId']!),
            ),
            routes: [
              GoRoute(
                path: StayModule.news.path,
                pageBuilder: (context, state) => _page(
                  context,
                  state,
                  StayNewsPage(stayId: state.pathParameters['stayId']!),
                ),
              ),
              GoRoute(
                path: StayModule.team.path,
                pageBuilder: (context, state) => _page(
                  context,
                  state,
                  StayTeamPage(stayId: state.pathParameters['stayId']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.admin,
            pageBuilder: (context, state) =>
                _page(context, state, const AdminPage()),
            routes: [
              GoRoute(
                path: AdminSection.stays.path,
                pageBuilder: (context, state) =>
                    _page(context, state, const StaysPage()),
              ),
              GoRoute(
                path: AdminSection.accounts.path,
                pageBuilder: (context, state) =>
                    _page(context, state, const AccountsPage()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}

/// Une page du cadre. Sur grand écran, passer d'un module à l'autre ne
/// s'anime pas : la barre latérale reste, seul le contenu change. Sur
/// téléphone, la transition du thème (`PageTransitions.compact`).
Page<void> _page(BuildContext context, GoRouterState state, Widget child) =>
    ShellLayout.forWidth(MediaQuery.sizeOf(context).width) == ShellLayout.drawer
    ? MaterialPage(key: state.pageKey, child: child)
    : NoTransitionPage(key: state.pageKey, child: child);

/// L'adresse où reprendre après la connexion : celle demandée au lancement si
/// c'en est une de l'app, sinon l'entrée.
String _resume(String? from) {
  final uri = from == null ? null : Uri.tryParse(from);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !uri.path.startsWith('/') ||
      AppRoutes.auth.contains(uri.path)) {
    return AppRoutes.start;
  }
  return uri.toString();
}
