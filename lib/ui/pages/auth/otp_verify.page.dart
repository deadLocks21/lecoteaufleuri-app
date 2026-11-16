import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/auth/auth_error_message.dart';

/// Seconde étape de la connexion : le code à 6 chiffres reçu par SMS.
class OtpVerifyPage extends ConsumerStatefulWidget {
  const OtpVerifyPage({super.key});

  /// Délai minimal entre deux envois, pour ménager le quota serveur
  /// (3 SMS par quart d'heure).
  static const resendCooldown = Duration(seconds: 60);

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  final _codeController = TextEditingController();
  Timer? _cooldownTimer;
  int _resendIn = 0;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _resendIn = OtpVerifyPage.resendCooldown.inSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    // En cas de succès l'état passe à `Authenticated` et `AuthGate` remplace
    // cette page par l'accueil.
    final error = await ref
        .read(sessionControllerProvider.notifier)
        .verifyOtp(_codeController.text);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error == null ? null : authErrorMessage(error);
    });
  }

  Future<void> _resend() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await ref
        .read(sessionControllerProvider.notifier)
        .resendOtp();

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error == null ? null : authErrorMessage(error);
    });
    if (error == null) {
      _codeController.clear();
      _startCooldown();
    }
  }

  void _back() =>
      ref.read(sessionControllerProvider.notifier).backToPhoneEntry();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(sessionControllerProvider);
    final phoneNumber = state is OtpRequested ? state.phoneNumber : '';
    final sessionExpired =
        state is OtpRequested && state.reason == OtpReason.sessionExpired;

    // Cette page est la racine pendant la connexion : le retour système ramène
    // à la saisie du numéro au lieu de quitter l'app.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_submitting) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('otpBackButton'),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Changer de numéro',
            onPressed: _submitting ? null : _back,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  Icon(Icons.sms, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Code de vérification',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saisissez le code à 6 chiffres envoyé au $phoneNumber.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (sessionExpired) ...[
                    const SizedBox(height: 16),
                    Card(
                      key: const Key('sessionExpiredBanner'),
                      color: theme.colorScheme.secondaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.lock_clock),
                        title: const Text(
                          'Votre session a expiré : un nouveau code vous a été '
                          'envoyé.',
                        ),
                        textColor: theme.colorScheme.onSecondaryContainer,
                        iconColor: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  TextField(
                    key: const Key('otpField'),
                    controller: _codeController,
                    autofocus: true,
                    enabled: !_submitting,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      letterSpacing: 8,
                    ),
                    onSubmitted: (_) => _verify(),
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      border: const OutlineInputBorder(),
                      errorText: _error,
                      errorMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('verifyOtpButton'),
                    onPressed: _submitting ? null : _verify,
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Valider'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('resendOtpButton'),
                    onPressed: _submitting || _resendIn > 0 ? null : _resend,
                    child: Text(
                      _resendIn > 0
                          ? 'Renvoyer un code dans $_resendIn s'
                          : 'Renvoyer un code',
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
