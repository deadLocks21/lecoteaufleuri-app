import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/user.dto.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/account.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/accounts.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/admin/account_error_message.dart';
import 'package:lecoteaufleuri/ui/widgets/phone_display.dart';

/// Fiche d'un compte : création ([account] absent) ou correction, statut
/// d'admin, coupure des sessions et suppression.
///
/// Se referme en rendant le message à afficher sur la liste.
class AccountEditPage extends ConsumerStatefulWidget {
  final UserDto? account;

  const AccountEditPage({super.key, this.account});

  @override
  ConsumerState<AccountEditPage> createState() => _AccountEditPageState();
}

class _AccountEditPageState extends ConsumerState<AccountEditPage> {
  late final _phone = TextEditingController(
    text: widget.account == null
        ? ''
        : displayPhone(widget.account!.phoneNumber),
  );
  late final _firstName = TextEditingController(
    text: widget.account?.firstName,
  );
  late final _lastName = TextEditingController(text: widget.account?.lastName);
  late bool _isAdmin = widget.account?.isAdmin ?? false;
  bool _busy = false;
  AccountErrorCode? _error;

  bool get _creating => widget.account == null;

  bool get _isSelf {
    final session = ref.read(sessionControllerProvider);
    return session is Authenticated &&
        session.session.user.id == widget.account?.id;
  }

  AccountsController get _accounts =>
      ref.read(accountsControllerProvider.notifier);

  @override
  void dispose() {
    _phone.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  /// Exécute [action] en bloquant l'écran ; rend `true` en cas de succès.
  Future<bool> _attempt(Future<AccountErrorCode?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await action();
    if (!mounted) return false;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == AccountErrorCode.notFound) {
      Navigator.of(context).pop(accountErrorMessage(error!));
    }
    return error == null;
  }

  /// Une erreur ne survit pas à la correction : dès qu'on retouche la saisie,
  /// elle disparaît jusqu'au prochain envoi.
  void _clearError(String _) {
    if (_error != null) setState(() => _error = null);
  }

  /// Ses propres changements (nom, statut) se voient tout de suite à l'accueil.
  void _refreshSelf() {
    if (_isSelf) {
      unawaited(ref.read(sessionControllerProvider.notifier).refresh());
    }
  }

  Future<void> _save() async {
    final ok = await _attempt(() async {
      final (_, error) = await _accounts.save(
        id: widget.account?.id,
        rawPhone: _phone.text,
        firstName: _firstName.text,
        lastName: _lastName.text,
      );
      return error;
    });
    if (ok && mounted) {
      _refreshSelf();
      Navigator.of(context).pop(_creating ? 'Compte créé.' : 'Compte modifié.');
    }
  }

  Future<void> _setAdmin(bool admin) async {
    final ok = await _attempt(() async {
      final (_, error) = await _accounts.setAdmin(
        widget.account!.id,
        admin: admin,
      );
      return error;
    });
    if (ok && mounted) {
      setState(() => _isAdmin = admin);
      _refreshSelf();
    }
  }

  Future<void> _revokeSessions() async {
    final confirmed = await _confirm(
      title: 'Couper les sessions ?',
      message: _isSelf
          ? 'Vous serez déconnecté de tous vos appareils, celui-ci compris.'
          : '${widget.account!.fullName} sera déconnecté de tous ses '
                'appareils et devra se reconnecter par SMS.',
      action: 'Couper',
    );
    if (!confirmed) return;
    final ok = await _attempt(
      () => _accounts.revokeSessions(widget.account!.id),
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sessions coupées.')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await _confirm(
      title: 'Supprimer ce compte ?',
      message:
          '${widget.account!.fullName} ne pourra plus se connecter. '
          'La suppression peut être annulée par l\'équipe technique.',
      action: 'Supprimer',
      destructive: true,
    );
    if (!confirmed) return;
    final ok = await _attempt(() => _accounts.delete(widget.account!.id));
    if (ok && mounted) Navigator.of(context).pop('Compte supprimé.');
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final colors = Theme.of(context).colorScheme;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                key: const Key('confirmButton'),
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: colors.error,
                        foregroundColor: colors.onError,
                      )
                    : null,
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    final phoneError = switch (error) {
      AccountErrorCode.invalidPhone ||
      AccountErrorCode.phoneTaken => accountErrorMessage(error!),
      _ => null,
    };
    // Seul le champ vide est signalé ; si le serveur refuse des noms que l'app
    // jugeait remplis, le message général prend le relais.
    final invalidName = error == AccountErrorCode.invalidName;
    final firstNameError = invalidName && _firstName.text.trim().isEmpty
        ? 'Le prénom est obligatoire.'
        : null;
    final lastNameError = invalidName && _lastName.text.trim().isEmpty
        ? 'Le nom est obligatoire.'
        : null;
    final fieldError = phoneError ?? firstNameError ?? lastNameError;
    final otherError = fieldError == null && error != null
        ? accountErrorMessage(error)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_creating ? 'Nouveau compte' : widget.account!.fullName),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                key: const Key('accountPhoneField'),
                controller: _phone,
                enabled: !_busy,
                onChanged: _clearError,
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
              const SizedBox(height: 16),
              TextField(
                key: const Key('accountFirstNameField'),
                controller: _firstName,
                enabled: !_busy,
                onChanged: _clearError,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  border: const OutlineInputBorder(),
                  errorText: firstNameError,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('accountLastNameField'),
                controller: _lastName,
                enabled: !_busy,
                onChanged: _clearError,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  border: const OutlineInputBorder(),
                  errorText: lastNameError,
                ),
              ),
              if (otherError != null) ...[
                const SizedBox(height: 16),
                Text(
                  otherError,
                  key: const Key('accountError'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('saveAccountButton'),
                onPressed: _busy ? null : _save,
                child: Text(_creating ? 'Créer le compte' : 'Enregistrer'),
              ),
              if (!_creating) ...[
                const SizedBox(height: 32),
                const Divider(),
                SwitchListTile(
                  key: const Key('adminSwitch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Admin de l\'association'),
                  subtitle: const Text('Tous les droits, partout'),
                  value: _isAdmin,
                  onChanged: _busy ? null : _setAdmin,
                ),
                const Divider(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('revokeSessionsButton'),
                  onPressed: _busy ? null : _revokeSessions,
                  icon: const Icon(Icons.phonelink_erase),
                  label: const Text('Couper les sessions'),
                ),
                if (!_isSelf) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: const Key('deleteAccountButton'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: _busy ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer le compte'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
