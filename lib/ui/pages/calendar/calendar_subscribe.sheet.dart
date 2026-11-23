import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/calendar_feed.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_error_message.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/occurrence_actions.dart';
import 'package:url_launcher/url_launcher.dart';

/// S'abonner au calendrier du séjour depuis son agenda (cf. `ACCES.md`,
/// « Calendrier du séjour ») : un lien personnel et secret, à ouvrir sur
/// iPhone ou Mac, dans Google Agenda, ou à copier.
Future<void> showCalendarSubscribeSheet(BuildContext context, String stayId) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _SubscribeSheet(stayId: stayId),
    );

class _SubscribeSheet extends ConsumerStatefulWidget {
  final String stayId;

  const _SubscribeSheet({required this.stayId});

  @override
  ConsumerState<_SubscribeSheet> createState() => _SubscribeSheetState();
}

class _SubscribeSheetState extends ConsumerState<_SubscribeSheet> {
  bool _renewing = false;

  void _tell(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _open(Uri url) async {
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _tell('Impossible d\'ouvrir ce lien ici : copiez-le dans votre agenda.');
    }
  }

  Future<void> _copy(CalendarFeedDto feed) async {
    await Clipboard.setData(ClipboardData(text: feed.url.toString()));
    if (mounted) _tell('Lien copié.');
  }

  Future<void> _renew() async {
    final confirmed = await confirm(
      context,
      title: 'Régénérer le lien ?',
      content:
          'L\'ancien lien cesse aussitôt de marcher : les agendas qui y sont '
          'abonnés devront reprendre le nouveau.',
      action: 'Régénérer',
    );
    if (!confirmed || !mounted) return;
    setState(() => _renewing = true);
    final error = await ref
        .read(calendarFeedControllerProvider(widget.stayId).notifier)
        .renew();
    if (!mounted) return;
    setState(() => _renewing = false);
    _tell(error == null ? 'Nouveau lien prêt.' : calendarErrorMessage(error));
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(calendarFeedControllerProvider(widget.stayId));
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Voir le calendrier dans mon agenda',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Votre agenda s\'abonne au calendrier du séjour et le suit en '
              'lecture seule. Ce lien est personnel : il ouvre le calendrier '
              'sans connexion, ne le partagez pas. Il cesse de marcher si vous '
              'quittez l\'équipe.',
              style: muted,
            ),
            const SizedBox(height: 16),
            switch ((feed.value, feed.error)) {
              (final CalendarFeedDto feed, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    key: const Key('subscribeApple'),
                    onPressed: () => _open(feed.webcal),
                    icon: const Icon(Icons.phone_iphone),
                    label: const Text('iPhone, iPad ou Mac'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    key: const Key('subscribeGoogle'),
                    onPressed: () => _open(feed.googleCalendar),
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('Google Agenda'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('copyFeed'),
                    onPressed: () => _copy(feed),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copier le lien'),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    feed.url.toString(),
                    key: const Key('feedUrl'),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Google Agenda relit un abonnement toutes les quelques '
                    'heures, l\'iPhone selon ses réglages (Réglages › '
                    'Calendrier › Comptes › Nouvelles données). Pour un '
                    'imprévu de dernière minute, l\'app fait foi.\n\n'
                    'Sur Android, abonnez-vous depuis Google Agenda sur le '
                    'web : l\'agenda suit ensuite sur le téléphone.',
                    style: muted,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('renewFeed'),
                      onPressed: _renewing ? null : _renew,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Régénérer le lien'),
                    ),
                  ),
                ],
              ),
              (_, final Object error) => Text(
                calendarErrorMessage(
                  error is CalendarException
                      ? error.code
                      : CalendarErrorCode.unknown,
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ],
        ),
      ),
    );
  }
}
