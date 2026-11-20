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
import 'package:lecoteaufleuri/ui/theme/page_transitions.dart';
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

/// Le cadre est-il celui du téléphone (tiroir et tuiles) ? Ailleurs, la
/// barre latérale montre les modules : pas de vue d'ensemble ni de flèche de
/// retour vers elle.
bool isCompactShell(BuildContext context) =>
    (ShellScope.maybeOf(context)?.layout ?? ShellLayout.drawer) ==
    ShellLayout.drawer;

/// Faut-il une flèche de retour en haut d'un module ? Sur téléphone, oui (on
/// revient aux tuiles) ; ailleurs, la barre latérale suffit.
bool shellShowsBack(BuildContext context) => isCompactShell(context);

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
    if (layout != ShellLayout.drawer) _leaveOverview(location);
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
          Expanded(
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(pageTransitionsTheme: PageTransitions.wide),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  /// Sur grand écran, la barre latérale tient lieu de vue d'ensemble : un
  /// séjour s'ouvre sur son premier module (les nouvelles, ouvertes à tous),
  /// l'administration sur ses séjours. Vaut aussi quand la fenêtre s'élargit
  /// sur une vue d'ensemble.
  void _leaveOverview(SpaceLocation location) {
    if (_overviewTarget(location) == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Toujours sur une vue d'ensemble, toujours sur grand écran ?
      final target = _overviewTarget(SpaceLocation.parse(widget.location));
      final wide =
          ShellLayout.forWidth(MediaQuery.sizeOf(context).width) !=
          ShellLayout.drawer;
      if (target != null && wide) context.go(target);
    });
  }

  static String? _overviewTarget(SpaceLocation? location) => switch (location) {
    StayLocation(:final stayId, module: null) => AppRoutes.stayModule(
      stayId,
      StayModule.news,
    ),
    AdminLocation(section: null) => AppRoutes.adminStays,
    _ => null,
  };
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

/// Une page de la barre latérale : un module du séjour, ou une page de
/// l'administration.
typedef _NavEntry = ({
  String key,
  String label,
  IconData icon,
  IconData selectedIcon,
  String target,
});

/// La barre latérale, dépliée (icônes et libellés) ou repliée en rail.
///
/// En tête, de quoi la replier, puis l'espace ouvert (le sélecteur de
/// séjour, ou le retour au séjour depuis l'administration) ; ensuite les
/// modules du séjour ou les pages de l'administration ; en pied,
/// l'administration et la déconnexion.
///
/// Les entrées portent les mêmes clés que les tuiles du téléphone
/// (`newsModule`, `staysSpace`…) : c'est le même geste, ouvrir ce module.
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
    final isAdmin = _viewer(ref)?.isAdmin ?? false;

    final (
      Widget? head,
      List<_NavEntry> entries,
      int? selected,
    ) = switch (location) {
      StayLocation(:final stayId, :final module) => () {
        final space = ref.watch(staySpaceProvider(stayId)).value;
        // Tant que le séjour se lit, les nouvelles (ouvertes à tous)
        // seules.
        final modules = space == null
            ? const [StayModule.news]
            : StayModule.openTo(space, isAdmin: isAdmin);
        final index = module == null ? -1 : modules.indexOf(module);
        return (
          _StaySwitcher(stayId: stayId, space: space, extended: extended),
          [
            for (final m in modules)
              (
                key: '${m.name}Module',
                label: m.label,
                icon: m.icon,
                selectedIcon: m.selectedIcon,
                target: AppRoutes.stayModule(stayId, m),
              ),
          ],
          index < 0 ? null : index,
        );
      }(),
      AdminLocation(:final section) => (
        lastStayId == null
            ? null
            : _NavItem(
                key: const Key('backToStay'),
                icon: Icons.arrow_back,
                label: 'Retour au séjour',
                extended: extended,
                onTap: () => context.go(AppRoutes.stay(lastStayId!)),
              ),
        [
          for (final s in AdminSection.values)
            (
              key: '${s.name}Space',
              label: s.label,
              icon: s.icon,
              selectedIcon: s.selectedIcon,
              target: s.location,
            ),
        ],
        section?.index,
      ),
    };

    return AnimatedContainer(
      duration: _navAnimation,
      curve: Curves.easeInOut,
      width: extended ? _extendedWidth : _collapsedWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // L'en-tête : dépliée, le logo à gauche et le bouton ☰ calé à
          // droite, qui suit le bord de la barre ; repliée, le bouton seul,
          // centré sur la colonne des icônes.
          // Dépliée, l'icône (24 points au milieu d'un bouton de 48) s'aligne
          // sur le bord droit de la carte du séjour ; repliée, elle se centre
          // sur la colonne des icônes.
          AnimatedPadding(
            duration: _navAnimation,
            curve: Curves.easeInOut,
            padding: EdgeInsets.fromLTRB(
              _navMargin,
              8,
              extended ? _navMargin - 12 : 20,
              16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Reveal(
                    visible: extended,
                    width: _extendedWidth - 2 * _navMargin + 12 - 48,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        height: 44,
                        child: AspectRatio(
                          aspectRatio: 948 / 523, // assets/brand/logo.png
                          child: Image.asset(
                            Theme.of(context).brightness == Brightness.dark
                                ? 'assets/brand/logo_dark.png'
                                : 'assets/brand/logo.png',
                            fit: BoxFit.contain,
                            semanticLabel: 'Domaine du Coteau Fleuri',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('toggleNav'),
                  icon: Icon(extended ? Icons.menu_open : Icons.menu),
                  tooltip: extended ? 'Replier le menu' : 'Déplier le menu',
                  onPressed: onToggle,
                ),
              ],
            ),
          ),
          ?head,
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final (index, entry) in entries.indexed)
                  _NavItem(
                    key: Key(entry.key),
                    icon: entry.icon,
                    selectedIcon: entry.selectedIcon,
                    label: entry.label,
                    selected: index == selected,
                    extended: extended,
                    onTap: () => context.go(entry.target),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (isAdmin && location is StayLocation)
            _NavItem(
              key: const Key('adminSpace'),
              icon: Icons.admin_panel_settings_outlined,
              label: 'Administration',
              extended: extended,
              onTap: () => context.go(AppRoutes.admin),
            ),
          _NavItem(
            key: const Key('logoutButton'),
            icon: Icons.logout,
            label: 'Se déconnecter',
            extended: extended,
            onTap: () => ref.read(sessionControllerProvider.notifier).logout(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Durée du repli et du dépli de la barre latérale.
const _navAnimation = Duration(milliseconds: 200);
const _collapsedWidth = 88.0;
const _extendedWidth = 256.0;

/// Marge de chaque entrée : avec elle, les icônes tombent au milieu de la
/// largeur repliée, et ne bougent pas quand la barre se déplie.
const _navMargin = 16.0;

/// Ce qui n'apparaît que la barre dépliée (libellés, détails du séjour) :
/// posé à sa largeur dépliée et dévoilé par la barre qui s'élargit, en
/// fondu, plutôt que remis en page à chaque instant de l'animation.
class _Reveal extends StatelessWidget {
  final bool visible;
  final double width;
  final Widget child;

  const _Reveal({
    required this.visible,
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => UnconstrainedBox(
    constrainedAxis: Axis.vertical,
    alignment: AlignmentDirectional.centerStart,
    clipBehavior: Clip.hardEdge,
    child: SizedBox(
      width: width,
      child: ExcludeSemantics(
        excluding: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: _navAnimation,
          curve: visible ? Curves.easeIn : Curves.easeOut,
          child: child,
        ),
      ),
    ),
  );
}

/// Une entrée de la barre latérale : une pastille qui s'étire avec la barre,
/// l'icône à gauche, le libellé dévoilé à droite. Repliée, le libellé passe
/// en infobulle.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.selected = false,
    required this.extended,
    required this.onTap,
  });

  /// La place du libellé, la barre dépliée.
  static const _labelWidth =
      _extendedWidth - 2 * _navMargin - 16 - 24 - 12 - 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _navMargin, vertical: 2),
      child: Tooltip(
        // Vide, l'infobulle ne s'affiche pas : le libellé est déjà visible.
        message: extended ? '' : label,
        child: Material(
          color: selected ? colors.secondaryContainer : Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    selected ? (selectedIcon ?? icon) : icon,
                    color: foreground,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Reveal(
                      visible: extended,
                      width: _labelWidth,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le séjour ouvert, en tête de la barre : son rôle et ses dates, et un menu
/// pour passer à un autre des séjours du compte (s'il en a d'autres).
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
    final mine = ref.watch(myStaysProvider).value ?? const <MyStayDto>[];
    final grouped = staysByPeriod(mine, calendarDay(DateTime.now()));
    final canSwitch = mine.any((m) => m.stay.id != stayId);
    final stay = space?.stay;
    final name = stay?.name ?? '';
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

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
                      Text(_staySubtitle(mine), style: muted),
                    ],
                  ),
                ),
              ),
          ],
      ],
      builder: (context, controller, _) {
        final onTap = canSwitch
            ? () => controller.isOpen ? controller.close() : controller.open()
            : null;
        // Une carte qui s'étire avec la barre : l'avatar à gauche, centré
        // sur la largeur repliée, et les détails dévoilés à droite. Repliée,
        // la carte s'efface : l'avatar reste seul, comme les autres icônes.
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: _navMargin),
          child: Tooltip(
            message: extended ? '' : name,
            child: Material(
              color: extended
                  ? theme.colorScheme.surfaceContainerLow
                  : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0),
              animationDuration: _navAnimation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: extended
                      ? theme.colorScheme.outlineVariant
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('staySwitcher'),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      StayAvatar(name: name, size: 36),
                      Expanded(
                        child: _Reveal(
                          visible: extended,
                          width: _detailsWidth,
                          child: Row(
                            children: [
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
                                    if (space != null) ...[
                                      Text(
                                        space!.role == null
                                            ? 'Administration'
                                            : staffRoleLabel(space!.role!),
                                        style: muted,
                                      ),
                                      Text(
                                        displayStayDates(
                                          stay!.startsOn,
                                          stay.endsOn,
                                        ),
                                        style: muted,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (canSwitch) const Icon(Icons.unfold_more),
                            ],
                          ),
                        ),
                      ),
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

  /// La place des détails à droite de l'avatar, la barre dépliée.
  static const _detailsWidth = _extendedWidth - 2 * _navMargin - 2 * 10 - 36;
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
