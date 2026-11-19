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

/// Nommer le directeur ou ajouter un adjoint d'un séjour.
///
/// On désigne la personne par son numéro de mobile : le directeur ne voit pas
/// la liste des comptes. L'admin, qui la voit, peut aussi choisir dans cette
/// liste. Un numéro sans compte en reçoit un : la page demande alors prénom et
/// nom. Se referme en rendant le message à afficher sur le séjour.
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

  bool get _director => widget.role == StaffRole.director;

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
  Future<void> _submit(String rawPhone, {bool create = false}) async {
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
        );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(switch ((create, _director)) {
        (true, true) => 'Compte créé, directeur ajouté.',
        (true, false) => 'Compte créé, adjoint ajouté.',
        (false, true) => 'Directeur ajouté.',
        (false, false) => 'Adjoint ajouté.',
      });
      return;
    }
    // Plus de séjour, ou plus le droit : rien à faire ici.
    if (error == StayErrorCode.notFound || error == StayErrorCode.forbidden) {
      Navigator.of(context).pop(stayErrorMessage(error));
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_director ? 'Ajouter un directeur' : 'Ajouter un adjoint'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                _director
                    ? 'Il rejoint les autres directeurs du séjour, avec les '
                          'mêmes droits. Un adjoint nommé directeur quitte les '
                          'adjoints.'
                    : 'L\'adjoint a les droits du directeur sur ce séjour, '
                          'sauf nommer ou retirer des adjoints.',
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
                child: Text(
                  _creating
                      ? 'Créer le compte et nommer'
                      : _director
                      ? 'Nommer directeur'
                      : 'Nommer adjoint',
                ),
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
