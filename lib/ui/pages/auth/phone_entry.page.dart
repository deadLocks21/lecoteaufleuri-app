import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/auth/auth_error_message.dart';

/// Première étape de la connexion : le numéro de mobile, pour recevoir un code
/// par SMS. Pas d'inscription : seuls les comptes existants passent.
class PhoneEntryPage extends ConsumerStatefulWidget {
  const PhoneEntryPage({super.key});

  @override
  ConsumerState<PhoneEntryPage> createState() => _PhoneEntryPageState();
}

class _PhoneEntryPageState extends ConsumerState<PhoneEntryPage> {
  final _phoneController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    // En cas de succès l'état passe à `OtpRequested` et `AuthGate` remplace
    // cette page par la saisie du code.
    final error = await ref
        .read(sessionControllerProvider.notifier)
        .requestOtp(_phoneController.text);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error == null ? null : authErrorMessage(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                // Le logo porte déjà le nom du domaine : pas de titre en plus.
                // Sa place est réservée (ratio de l'image) pour que la page ne
                // saute pas quand il finit de se charger.
                Center(
                  child: SizedBox(
                    width: 260,
                    child: AspectRatio(
                      aspectRatio: 948 / 523, // assets/brand/logo.png
                      child: Image.asset(
                        theme.brightness == Brightness.dark
                            ? 'assets/brand/logo_dark.png'
                            : 'assets/brand/logo.png',
                        key: const Key('brandLogo'),
                        fit: BoxFit.contain,
                        semanticLabel: 'Domaine du Coteau Fleuri',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Saisissez votre numéro de mobile : '
                  'nous vous enverrons un code par SMS.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  key: const Key('phoneNumberField'),
                  controller: _phoneController,
                  autofocus: true,
                  enabled: !_submitting,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  // `\s` et non une simple espace : un numéro collé ou
                  // autorempli peut être séparé par des espaces insécables.
                  // `PhoneNumber.parse` retire tous ces séparateurs.
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s.\-+()]')),
                  ],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Numéro de mobile',
                    hintText: '06 12 34 56 78',
                    prefixIcon: const Icon(Icons.phone_android),
                    border: const OutlineInputBorder(),
                    errorText: _error,
                    errorMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('requestOtpButton'),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Recevoir le code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
