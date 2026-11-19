import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/user.dto.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/infrastructure/providers/accounts.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_detail.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/admin/stay_error_message.dart';
import 'package:lecoteaufleuri/ui/widgets/phone_display.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

/// Ajouter un directeur, un adjoint ou un animateur à un séjour.
///
/// On désigne la personne par son numéro de mobile : le directeur ne voit pas
/// la liste des comptes. L'admin, qui la voit, peut aussi choisir dans cette
/// liste. Un numéro sans compte en reçoit un : la page demande alors prénom et
/// nom. Un membre de la direction ne passe animateur qu'après confirmation, et
/// si le compte connecté peut le retirer de son rôle. Se referme en rendant le
/// message à afficher sur le séjour.
class StaffPickerPage extends ConsumerStatefulWidget {
  final String stayId;
  final StaffRole role;

  const StaffPickerPage({super.key, required this.stayId, required this.role});

  @override
  ConsumerState<StaffPickerPage> createState() => _StaffPickerPageState();
}

class _StaffPickerPageState extends ConsumerState<StaffPickerPage> {
  final _phone = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _search = TextEditingController();
  bool _busy = false;
  StayErrorCode? _error;

  /// Le numéro saisi pour lequel l'API n'a trouvé aucun compte : tant qu'il
  /// reste dans le champ, on demande prénom et nom pour le lui créer.
  String? _unknownNumber;

  bool get _creating => _unknownNumber != null;

  @override
  void dispose() {
    _phone.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Nomme le compte de [rawPhone] ; en création, avec les noms saisis.
  /// [demoting] : le rôle de direction qu'il quitte pour passer animateur,
  /// une fois confirmé.
  Future<void> _submit(
    String rawPhone, {
    bool create = false,
    StaffRole? demoting,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref
        .read(stayDetailControllerProvider(widget.stayId).notifier)
        .name(
          widget.role,
          rawPhone: rawPhone,
          firstName: create ? _firstName.text : null,
          lastName: create ? _lastName.text : null,
          demote: demoting != null,
        );
    if (!mounted) return;
    if (error == null) {
      final role = staffRoleLabel(widget.role);
      final named = role.toLowerCase();
      Navigator.of(context).pop(switch ((create, demoting)) {
        (_, final StaffRole from) => '${staffRoleLabel(from)} passé $named.',
        (true, null) => 'Compte créé, $named ajouté.',
        (false, null) => '$role ajouté.',
      });
      return;
    }
    // Plus de séjour, ou plus le droit : rien à faire ici.
    if (error == StayErrorCode.notFound || error == StayErrorCode.forbidden) {
      Navigator.of(context).pop(stayErrorMessage(error));
      return;
    }
    // Un membre de la direction que l'on peut faire passer animateur : on
    // demande d'abord.
    final from = _demotable(error);
    if (from != null) {
      setState(() => _busy = false);
      if (await _confirmDemotion(from) && mounted) {
        await _submit(rawPhone, create: create, demoting: from);
      }
      return;
    }
    setState(() {
      _busy = false;
      if (error == StayErrorCode.unknownPhone) {
        // Pas de compte : on propose de le créer, ce n'est pas une erreur.
        _unknownNumber = rawPhone;
      } else {
        _error = error;
      }
    });
  }

  /// Le rôle de direction que tient le compte visé, si [error] le signale et
  /// que le compte connecté peut l'en retirer (ce que l'API revérifie) ; null
  /// sinon : l'erreur s'affiche alors sous le numéro.
  StaffRole? _demotable(StayErrorCode error) {
    if (widget.role != StaffRole.animator) return null;
    final detail = ref.read(stayDetailControllerProvider(widget.stayId)).value;
    return switch (error) {
      StayErrorCode.alreadyDirector when detail?.canManageDirectors ?? false =>
        StaffRole.director,
      StayErrorCode.alreadyDeputy when detail?.canManageDeputies ?? false =>
        StaffRole.deputy,
      _ => null,
    };
  }

  Future<bool> _confirmDemotion(StaffRole from) async {
    final who = from == StaffRole.director
        ? 'Cette personne dirige le séjour.'
        : 'Cette personne fait partie des adjoints du séjour.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Passer animateur ?'),
        content: Text(
          '$who En passant animateur, elle quittera la direction et n\'aura '
          'plus la main sur l\'équipe.',
          key: const Key('demoteHint'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('confirmDemoteButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Passer animateur'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  /// Un autre numéro n'est plus celui à qui l'on crée un compte.
  void _phoneChanged(String value) {
    _clearError();
    if (_creating && value != _unknownNumber) {
      setState(() => _unknownNumber = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionControllerProvider);
    final isAdmin = session is Authenticated && session.session.user.isAdmin;
    final error = _error;
    const fieldErrors = {
      StayErrorCode.invalidPhone,
      StayErrorCode.unknownPhone,
      StayErrorCode.alreadyDirector,
      StayErrorCode.alreadyDeputy,
    };
    final phoneError = fieldErrors.contains(error)
        ? stayErrorMessage(error!)
        : null;
    // Seul le nom vide est signalé ; si le serveur refuse des noms que l'app
    // jugeait remplis, le message général prend le relais.
    final invalidName = error == StayErrorCode.invalidPersonName;
    final firstNameError = invalidName && _firstName.text.trim().isEmpty
        ? 'Le prénom est obligatoire.'
        : null;
    final lastNameError = invalidName && _lastName.text.trim().isEmpty
        ? 'Le nom est obligatoire.'
        : null;
    final fieldError = phoneError ?? firstNameError ?? lastNameError;
    final otherError = error != null && fieldError == null
        ? stayErrorMessage(error)
        : null;

    final (title, help, action) = switch (widget.role) {
      StaffRole.director => (
        'Ajouter un directeur',
        'Il rejoint les autres directeurs du séjour, avec les mêmes droits. '
            'Un adjoint ou un animateur nommé directeur quitte son rôle.',
        'Nommer directeur',
      ),
      StaffRole.deputy => (
        'Ajouter un adjoint',
        'L\'adjoint a les droits du directeur sur ce séjour, sauf nommer ou '
            'retirer des adjoints. Un animateur nommé adjoint quitte les '
            'animateurs.',
        'Nommer adjoint',
      ),
      StaffRole.animator => (
        'Ajouter un animateur',
        'L\'animateur rejoint l\'équipe du séjour, sans la main sur '
            'l\'équipe.',
        'Nommer animateur',
      ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                help,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('staffPhoneField'),
                controller: _phone,
                enabled: !_busy,
                onChanged: _phoneChanged,
                onSubmitted: _busy || _creating ? null : _submit,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s.\-+()]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Numéro de mobile',
                  hintText: '06 12 34 56 78',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: const OutlineInputBorder(),
                  errorText: phoneError,
                ),
              ),
              if (_creating) ...[
                const SizedBox(height: 16),
                Text(
                  'Aucun compte pour ce numéro : donnez le prénom et le nom '
                  'de la personne pour lui en créer un. Elle pourra ensuite se '
                  'connecter avec ce numéro.',
                  key: const Key('newAccountHint'),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('staffFirstNameField'),
                  controller: _firstName,
                  enabled: !_busy,
                  autofocus: true,
                  onChanged: (_) => _clearError(),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                    border: const OutlineInputBorder(),
                    errorText: firstNameError,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('staffLastNameField'),
                  controller: _lastName,
                  enabled: !_busy,
                  onChanged: (_) => _clearError(),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    border: const OutlineInputBorder(),
                    errorText: lastNameError,
                  ),
                ),
              ],
              if (otherError != null) ...[
                const SizedBox(height: 16),
                Text(
                  otherError,
                  key: const Key('staffError'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('nameStaffButton'),
                onPressed: _busy
                    ? null
                    : () => _submit(_phone.text, create: _creating),
                child: Text(_creating ? 'Créer le compte et nommer' : action),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 32),
                Text(
                  'Ou choisissez un compte',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('staffSearchField'),
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Nom ou numéro',
                    border: OutlineInputBorder(),
                  ),
                ),
                _AccountList(
                  search: _search.text,
                  enabled: !_busy,
                  onPick: (account) => _submit(account.phoneNumber),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Les comptes de l'association (admins seulement), filtrés par nom ou
/// numéro ; en choisir un le nomme.
class _AccountList extends ConsumerWidget {
  final String search;
  final bool enabled;
  final ValueChanged<UserDto> onPick;

  const _AccountList({
    required this.search,
    required this.enabled,
    required this.onPick,
  });

  bool _matches(UserDto account) {
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return true;
    final digits = query.replaceAll(RegExp(r'\D'), '');
    return account.fullName.toLowerCase().contains(query) ||
        (digits.isNotEmpty &&
            displayPhone(
              account.phoneNumber,
            ).replaceAll(' ', '').contains(digits));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsControllerProvider).value;
    if (accounts == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        for (final account in accounts.where(_matches))
          ListTile(
            key: Key('pickAccount-${account.id}'),
            enabled: enabled,
            leading: CircleAvatar(
              child: Text(
                account.firstName.isEmpty ? '?' : account.firstName[0],
              ),
            ),
            title: Text(account.fullName),
            subtitle: Text(displayPhone(account.phoneNumber)),
            onTap: () => onPick(account),
          ),
      ],
    );
  }
}
