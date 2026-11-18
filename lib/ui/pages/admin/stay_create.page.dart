import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stays.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/admin/stay_error_message.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

/// Création d'un séjour : nom, nature (ACM ou non) et dates.
///
/// Se referme en rendant le message à afficher sur la liste.
class StayCreatePage extends ConsumerStatefulWidget {
  const StayCreatePage({super.key});

  @override
  ConsumerState<StayCreatePage> createState() => _StayCreatePageState();
}

class _StayCreatePageState extends ConsumerState<StayCreatePage> {
  final _name = TextEditingController();
  final _dates = TextEditingController();
  StayKind? _kind;
  DateTimeRange? _range;
  bool _busy = false;
  StayErrorCode? _error;

  @override
  void dispose() {
    _name.dispose();
    _dates.dispose();
    super.dispose();
  }

  /// Une erreur ne survit pas à la correction : dès qu'on retouche la saisie,
  /// elle disparaît jusqu'au prochain envoi.
  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _pickDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final range = await showDateRangePicker(
      context: context,
      // Un séjour tout juste passé peut encore s'enregistrer.
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 5, 12, 31),
      initialDateRange: _range,
      currentDate: today,
      helpText: 'Dates du séjour',
      saveText: 'Valider',
      confirmText: 'Valider',
      fieldStartLabelText: 'Premier jour',
      fieldEndLabelText: 'Dernier jour',
    );
    if (range == null || !mounted) return;
    _clearError();
    setState(() {
      _range = range;
      _dates.text = displayStayDates(range.start, range.end);
    });
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final (_, error) = await ref
        .read(staysControllerProvider.notifier)
        .create(
          name: _name.text,
          kind: _kind,
          startsOn: _range?.start,
          endsOn: _range?.end,
        );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop('Séjour créé.');
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    String? errorFor(StayErrorCode code) =>
        error == code ? stayErrorMessage(code) : null;
    final otherError =
        error == null ||
            const {
              StayErrorCode.invalidName,
              StayErrorCode.invalidKind,
              StayErrorCode.invalidDates,
            }.contains(error)
        ? null
        : stayErrorMessage(error);
    final kindError = errorFor(StayErrorCode.invalidKind);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau séjour')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                key: const Key('stayNameField'),
                controller: _name,
                enabled: !_busy,
                onChanged: (_) => _clearError(),
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(StayDraft.nameMaxLength),
                ],
                decoration: InputDecoration(
                  labelText: 'Nom du séjour',
                  hintText: 'Été 2027 — Pyrénées',
                  border: const OutlineInputBorder(),
                  errorText: errorFor(StayErrorCode.invalidName),
                ),
              ),
              const SizedBox(height: 24),
              Text('Nature du séjour', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<StayKind>(
                key: const Key('stayKindSelector'),
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                segments: [
                  for (final kind in StayKind.values)
                    ButtonSegment(
                      value: kind,
                      label: Text(stayKindLabel(kind)),
                      icon: Icon(switch (kind) {
                        StayKind.acm => Icons.child_care,
                        StayKind.other => Icons.groups_outlined,
                      }),
                    ),
                ],
                selected: {?_kind},
                onSelectionChanged: _busy
                    ? null
                    : (selection) {
                        _clearError();
                        setState(() => _kind = selection.firstOrNull);
                      },
              ),
              const SizedBox(height: 8),
              Text(
                kindError ??
                    (_kind == null
                        ? 'Un accueil collectif de mineurs (ACM), ou un '
                              'séjour où chacun s\'inscrit en son nom.'
                        : stayKindDescription(_kind!)),
                key: const Key('stayKindHelp'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: kindError == null
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                key: const Key('stayDatesField'),
                controller: _dates,
                enabled: !_busy,
                readOnly: true,
                onTap: _pickDates,
                decoration: InputDecoration(
                  labelText: 'Dates',
                  hintText: 'Premier et dernier jour',
                  prefixIcon: const Icon(Icons.date_range),
                  border: const OutlineInputBorder(),
                  errorText: errorFor(StayErrorCode.invalidDates),
                ),
              ),
              if (otherError != null) ...[
                const SizedBox(height: 16),
                Text(
                  otherError,
                  key: const Key('stayError'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('saveStayButton'),
                onPressed: _busy ? null : _save,
                child: const Text('Créer le séjour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
