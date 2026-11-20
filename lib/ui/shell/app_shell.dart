import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/core/application/stay_periods.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/infrastructure/providers/my_stays.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_space.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stays.service_provider.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay_modules.dart';
import 'package:lecoteaufleuri/ui/router/app_routes.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

/// Comment le cadre présente la navigation, selon la largeur de la fenêtre.
enum ShellLayout {
  /// Téléphone (moins de 600 points) : un tiroir ☰ pour changer d'espace, des
  /// tuiles pour ouvrir un module.
  drawer,

  /// Tablette, fenêtre étroite (moins de 1000 points) : un rail d'icônes,
  /// qu'on peut déplier.
  rail,

  /// Grand écran : la barre latérale dépliée, qu'on peut replier en rail.
  sidebar;

  static ShellLayout forWidth(double width) => width < 600
      ? ShellLayout.drawer
      : width < 1000
      ? ShellLayout.rail
      : ShellLayout.sidebar;
}

/// Ce que le cadre offre aux pages qu'il entoure.
class ShellScope extends InheritedWidget {
  final ShellLayout layout;
  final VoidCallback openDrawer;

  const ShellScope({
    super.key,
    required this.layout,
    required this.openDrawer,
    required super.child,
  });

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => layout != oldWidget.layout;
}

/// Le bouton ☰ d'une page d'entrée d'espace (vue d'ensemble d'un séjour, de
/// l'administration), seulement sur téléphone : ailleurs, la navigation est à
/// gauche, toujours visible.
Widget? shellMenuButton(BuildContext context) {
  final scope = ShellScope.maybeOf(context);
  if (scope?.layout != ShellLayout.drawer) return null;
  return IconButton(
    key: const Key('menuButton'),
    icon: const Icon(Icons.menu),
    tooltip: 'Menu',
    onPressed: scope!.openDrawer,
  );
}

/// Faut-il une flèche de retour en haut d'un module ? Sur téléphone, oui (on
/// revient aux tuiles) ; ailleurs, le menu de gauche suffit.
bool shellShowsBack(BuildContext context) =>
    (ShellScope.maybeOf(context)?.layout ?? ShellLayout.drawer) ==
    ShellLayout.drawer;

/// Le cadre de l'app connectée : la navigation entre espaces (les séjours du
/// compte, l'administration) et entre les modules de l'espace ouvert, autour
/// de la page courante [child].
///
/// Il retient aussi le séjour ouvert, pour y revenir au prochain lancement.
class AppShell extends ConsumerStatefulWidget {
  final Uri location;
  final Widget child;

  const AppShell({super.key, required this.location, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Choix explicite de l'utilisateur (déplier, replier) ; sinon, selon la
  /// largeur.
  bool? _extended;

  /// Le dernier séjour ouvert, pour en revenir depuis l'administration.
  String? _lastStayId;

  @override
  void initState() {
    super.initState();
    _remember(SpaceLocation.parse(widget.location));
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _remember(SpaceLocation.parse(widget.location));
  }

  void _remember(SpaceLocation? location) {
    if (location is! StayLocation || location.stayId == _lastStayId) return;
    _lastStayId = location.stayId;
    final state = ref.read(sessionControllerProvider);
    if (state is Authenticated) {
      ref
          .read(staysServiceProvider)
          .remember
          .execute(state.session.user.id, location.stayId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = SpaceLocation.parse(widget.location);
    // Hors de tout espace (démarrage, accueil vide), la page est seule.
    if (location == null) return widget.child;

    final layout = ShellLayout.forWidth(MediaQuery.sizeOf(context).width);
    final child = ShellScope(
      layout: layout,
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      // Les messages d'une page s'affichent au bas de cette page, au-dessus
      // de ses boutons, et non au bas du cadre.
      child: ScaffoldMessenger(child: widget.child),
    );

    if (layout == ShellLayout.drawer) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: _NavDrawer(location: location),
        body: child,
      );
    }
    final extended = _extended ?? layout == ShellLayout.sidebar;
    return Material(
      child: Row(
        children: [
          _SideNav(
            location: location,
            extended: extended,
            lastStayId: _lastStayId,
            onToggle: () => setState(() => _extended = !extended),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Le compte connecté, s'il l'est encore.
({String firstName, bool isAdmin})? _viewer(WidgetRef ref) =>
    switch (ref.watch(sessionControllerProvider)) {
      Authenticated(:final session) => (
        firstName: session.user.firstName,
        isAdmin: session.user.isAdmin,
      ),
      _ => null,
    };

const _periodLabels = {
  StayPeriod.current: 'En cours',
  StayPeriod.upcoming: 'À venir',
  StayPeriod.past: 'Passés',
};

String _staySubtitle(MyStayDto mine) =>
    '${staffRoleLabel(mine.role)} · '
    '${displayStayDates(mine.stay.startsOn, mine.stay.endsOn)}';

/// Le tiroir du téléphone : les séjours du compte par période, puis
/// l'administration et la déconnexion.
class _NavDrawer extends ConsumerWidget {
  final SpaceLocation location;

  const _NavDrawer({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewer = _viewer(ref);
    final myStays = ref.watch(myStaysProvider);
    final grouped = staysByPeriod(
      myStays.value ?? const [],
      calendarDay(DateTime.now()),
    );
    final openStayId = switch (location) {
      StayLocation(:final stayId) => stayId,
      _ => null,
    };

    void go(String target) {
      Navigator.of(context).pop();
      context.go(target);
    }

    Widget stayTile(MyStayDto mine) => ListTile(
      key: Key('myStay-${mine.stay.id}'),
      leading: StayAvatar(name: mine.stay.name),
      title: Text(mine.stay.name),
      subtitle: Text(_staySubtitle(mine)),
      selected: mine.stay.id == openStayId,
      onTap: () => go(AppRoutes.stay(mine.stay.id)),
    );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    final past = grouped[StayPeriod.past]!;
    // Un séjour ouvert hors des siens (un admin venu de la liste de
    // l'association) reste visible en tête.
    final mineIds = {for (final m in myStays.value ?? const []) m.stay.id};
    final other = openStayId == null || mineIds.contains(openStayId)
        ? null
        : ref.watch(staySpaceProvider(openStayId)).value;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              title: Text(
                'Le Coteau Fleuri',
                style: theme.textTheme.titleLarge,
              ),
              subtitle: Text('Bonjour ${viewer?.firstName ?? ''} !'),
            ),
            if (other != null) ...[
              label('Séjour ouvert'),
              ListTile(
                key: Key('openStay-${other.stay.id}'),
                leading: StayAvatar(name: other.stay.name),
                title: Text(other.stay.name),
                subtitle: Text(
                  displayStayDates(other.stay.startsOn, other.stay.endsOn),
                ),
                selected: true,
                onTap: () => go(AppRoutes.stay(other.stay.id)),
              ),
            ],
            for (final period in [StayPeriod.current, StayPeriod.upcoming])
              if (grouped[period]!.isNotEmpty) ...[
                label(_periodLabels[period]!),
                ...grouped[period]!.map(stayTile),
              ],
            if (past.isNotEmpty)
              ExpansionTile(
                key: const Key('pastStays'),
                title: Text(
                  '${_periodLabels[StayPeriod.past]} (${past.length})',
                ),
                initiallyExpanded: past.any((m) => m.stay.id == openStayId),
                children: past.map(stayTile).toList(),
              ),
            if (myStays.hasError && !myStays.isLoading)
              ListTile(
                key: const Key('myStaysError'),
                title: const Text('Vos séjours n\'ont pas pu être chargés.'),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(myStaysProvider),
                  child: const Text('Réessayer'),
                ),
              ),
            const Divider(),
            if (viewer?.isAdmin ?? false)
              ListTile(
                key: const Key('adminSpace'),
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Administration'),
                selected: location is AdminLocation,
                onTap: () => go(AppRoutes.admin),
              ),
            ListTile(
              key: const Key('logoutButton'),
              leading: const Icon(Icons.logout),
              title: const Text('Se déconnecter'),
              onTap: () =>
                  ref.read(sessionControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le rail ou la barre latérale : l'espace ouvert en tête (le sélecteur de
/// séjour, ou le retour au séjour depuis l'administration), ses pages, puis
/// l'administration, la déconnexion et de quoi replier ou déplier.
class _SideNav extends ConsumerWidget {
  final SpaceLocation location;
  final bool extended;
  final String? lastStayId;
  final VoidCallback onToggle;

  const _SideNav({
    required this.location,
    required this.extended,
    required this.lastStayId,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewer = _viewer(ref);
    final isAdmin = viewer?.isAdmin ?? false;

    final (
      Widget leading,
      List<
        ({
          String key,
          String label,
          IconData icon,
          IconData selectedIcon,
          String target,
        })
      >
      pages,
      int? selected,
    ) = switch (location) {
      StayLocation(:final stayId, :final module) => () {
        final space = ref.watch(staySpaceProvider(stayId)).value;
        // Tant que le séjour se lit, les nouvelles (ouvertes à tous) seules.
        final modules = space == null
            ? const [StayModule.news]
            : StayModule.openTo(space, isAdmin: isAdmin);
        final index = module == null ? 0 : modules.indexOf(module) + 1;
        return (
          _StaySwitcher(stayId: stayId, space: space, extended: extended),
          [
            (
              key: 'nav-overview',
              label: 'Vue d\'ensemble',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              target: AppRoutes.stay(stayId),
            ),
            for (final m in modules)
              (
                key: 'nav-${m.name}',
                label: m.label,
                icon: m.icon,
                selectedIcon: m.selectedIcon,
                target: AppRoutes.stayModule(stayId, m),
              ),
          ],
          index > 0 || module == null ? index : null,
        );
      }(),
      AdminLocation(:final section) => (
        lastStayId == null
            ? const SizedBox(height: 8)
            : _NavButton(
                key: const Key('backToStay'),
                icon: Icons.arrow_back,
                label: 'Retour au séjour',
                extended: extended,
                onPressed: () => context.go(AppRoutes.stay(lastStayId!)),
              ),
        [
          (
            key: 'nav-admin',
            label: 'Administration',
            icon: Icons.admin_panel_settings_outlined,
            selectedIcon: Icons.admin_panel_settings,
            target: AppRoutes.admin,
          ),
          (
            key: 'nav-adminStays',
            label: 'Séjours',
            icon: Icons.cabin_outlined,
            selectedIcon: Icons.cabin,
            target: AppRoutes.adminStays,
          ),
          (
            key: 'nav-adminAccounts',
            label: 'Comptes',
            icon: Icons.manage_accounts_outlined,
            selectedIcon: Icons.manage_accounts,
            target: AppRoutes.adminAccounts,
          ),
        ],
        switch (section) {
          null => 0,
          AdminSection.stays => 1,
          AdminSection.accounts => 2,
        },
      ),
    };

    return NavigationRail(
      extended: extended,
      minExtendedWidth: 256,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      selectedIndex: selected,
      onDestinationSelected: (index) => context.go(pages[index].target),
      leading: leading,
      trailing: Expanded(
        child: Align(
          alignment: extended ? Alignment.bottomLeft : Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAdmin && location is StayLocation)
                  _NavButton(
                    key: const Key('adminSpace'),
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Administration',
                    extended: extended,
                    onPressed: () => context.go(AppRoutes.admin),
                  ),
                _NavButton(
                  key: const Key('logoutButton'),
                  icon: Icons.logout,
                  label: 'Se déconnecter',
                  extended: extended,
                  onPressed: () =>
                      ref.read(sessionControllerProvider.notifier).logout(),
                ),
                _NavButton(
                  key: const Key('toggleNav'),
                  icon: extended
                      ? Icons.keyboard_double_arrow_left
                      : Icons.keyboard_double_arrow_right,
                  label: extended ? 'Replier' : 'Déplier',
                  extended: extended,
                  onPressed: onToggle,
                ),
              ],
            ),
          ),
        ),
      ),
      destinations: [
        for (final page in pages)
          NavigationRailDestination(
            icon: Icon(page.icon, key: Key(page.key)),
            selectedIcon: Icon(page.selectedIcon, key: Key(page.key)),
            label: Text(page.label),
          ),
      ],
    );
  }
}

/// Un bouton du pied du rail : icône seule (avec infobulle) replié, icône et
/// libellé déplié.
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool extended;
  final VoidCallback onPressed;

  const _NavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.extended,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return IconButton(icon: Icon(icon), tooltip: label, onPressed: onPressed);
    }
    return SizedBox(
      width: 232,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}

/// Le séjour ouvert, en tête du rail : un menu pour passer à un autre séjour
/// du compte (et, pour un admin, à la liste de tous).
class _StaySwitcher extends ConsumerWidget {
  final String stayId;
  final StaySpaceDto? space;
  final bool extended;

  const _StaySwitcher({
    required this.stayId,
    required this.space,
    required this.extended,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAdmin = _viewer(ref)?.isAdmin ?? false;
    final grouped = staysByPeriod(
      ref.watch(myStaysProvider).value ?? const [],
      calendarDay(DateTime.now()),
    );
    final name = space?.stay.name ?? '';

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return MenuAnchor(
      alignmentOffset: const Offset(8, 4),
      menuChildren: [
        for (final period in StayPeriod.values)
          if (grouped[period]!.isNotEmpty) ...[
            header(_periodLabels[period]!),
            for (final mine in grouped[period]!)
              MenuItemButton(
                key: Key('myStay-${mine.stay.id}'),
                leadingIcon: StayAvatar(name: mine.stay.name, size: 28),
                trailingIcon: mine.stay.id == stayId
                    ? const Icon(Icons.check, size: 18)
                    : null,
                onPressed: () => context.go(AppRoutes.stay(mine.stay.id)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mine.stay.name),
                      Text(
                        _staySubtitle(mine),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        if (isAdmin) ...[
          const Divider(),
          MenuItemButton(
            key: const Key('allStays'),
            leadingIcon: const Icon(Icons.cabin_outlined),
            onPressed: () => context.go(AppRoutes.adminStays),
            child: const Text('Tous les séjours de l\'association'),
          ),
        ],
      ],
      builder: (context, controller, _) {
        void toggle() =>
            controller.isOpen ? controller.close() : controller.open();
        if (!extended) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Tooltip(
              message: name,
              child: InkWell(
                key: const Key('staySwitcher'),
                borderRadius: BorderRadius.circular(12),
                onTap: toggle,
                child: StayAvatar(name: name, size: 40),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SizedBox(
            width: 232,
            child: Material(
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('staySwitcher'),
                onTap: toggle,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      StayAvatar(name: name, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                            if (space != null)
                              Text(
                                space!.role == null
                                    ? 'Administration'
                                    : staffRoleLabel(space!.role!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.unfold_more),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Les initiales d'un séjour, pour le reconnaître dans un rail ou une liste :
/// les premières lettres de ses deux premiers mots (« Été 2027 — Pyrénées »
/// donne « ÉP »).
class StayAvatar extends StatelessWidget {
  final String name;
  final double size;

  const StayAvatar({super.key, required this.name, this.size = 36});

  static String initials(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where(
          (w) => w.isNotEmpty && RegExp(r'^\p{L}', unicode: true).hasMatch(w),
        )
        .take(2);
    final letters = words.map((w) => w.characters.first.toUpperCase()).join();
    return letters.isEmpty && name.isNotEmpty
        ? name.characters.first.toUpperCase()
        : letters;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        initials(name),
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
