import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stays.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/admin/stay_error_message.dart';
import 'package:lecoteaufleuri/ui/router/app_routes.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

/// Création ou modification d'un séjour : nom, nature (ACM ou non) et dates.
///
/// Sans [stay], un nouveau séjour ; avec, ce séjour à modifier, et de quoi
/// ouvrir sa page. Se referme en rendant le message à afficher sur la liste.
class StayFormPage extends ConsumerStatefulWidget {
  final StayDto? stay;

  const StayFormPage({super.key, this.stay});

  @override
  ConsumerState<StayFormPage> createState() => _StayFormPageState();
}

class _StayFormPageState extends ConsumerState<StayFormPage> {
  late final _name = TextEditingController(text: widget.stay?.name);
  late final _dates = TextEditingController(
    text: switch (widget.stay) {
      final StayDto stay => displayStayDates(stay.startsOn, stay.endsOn),
      null => null,
    },
  );
  late StayKind? _kind = widget.stay?.kind;
  late DateTimeRange? _range = switch (widget.stay) {
    final StayDto stay => DateTimeRange(
      start: _localDay(stay.startsOn),
      end: _localDay(stay.endsOn),
    ),
    null => null,
  };
  bool _busy = false;
  StayErrorCode? _error;

  bool get _editing => widget.stay != null;

  /// Un jour du séjour (minuit UTC) au jour local que le calendrier affiche.
  static DateTime _localDay(DateTime day) =>
      DateTime(day.year, day.month, day.day);

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
    // Un séjour tout juste passé peut encore s'enregistrer ; un séjour plus
    // ancien se corrige depuis ses propres dates.
    final earliest = DateTime(today.year - 1);
    final start = _range?.start;
    final range = await showDateRangePicker(
      context: context,
      firstDate: start != null && start.isBefore(earliest) ? start : earliest,
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
    final controller = ref.read(staysControllerProvider.notifier);
    final stay = widget.stay;
    final (_, error) = stay == null
        ? await controller.create(
            name: _name.text,
            kind: _kind,
            startsOn: _range?.start,
            endsOn: _range?.end,
          )
        : await controller.edit(
            stay.id,
            name: _name.text,
            kind: _kind,
            startsOn: _range?.start,
            endsOn: _range?.end,
          );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(_editing ? 'Séjour modifié.' : 'Séjour créé.');
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  /// La page du séjour, comme sa ligne dans « Mes séjours » : l'adresse
  /// remplace l'administration.
  void _openStay() => context.go(AppRoutes.stay(widget.stay!.id));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    String? errorFor(Set<StayErrorCode> codes) =>
        codes.contains(error) ? stayErrorMessage(error!) : null;
    const kindErrors = {StayErrorCode.invalidKind, StayErrorCode.hasTeam};
    const datesErrors = {
      StayErrorCode.invalidDates,
      StayErrorCode.entriesOutsideDates,
    };
    final otherError =
        error == null ||
            error == StayErrorCode.invalidName ||
            kindErrors.contains(error) ||
            datesErrors.contains(error)
        ? null
        : stayErrorMessage(error);
    final kindError = errorFor(kindErrors);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Modifier le séjour' : 'Nouveau séjour'),
      ),
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
                  errorText: errorFor(const {StayErrorCode.invalidName}),
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
                  errorText: errorFor(datesErrors),
                  errorMaxLines: 3,
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
                child: Text(_editing ? 'Enregistrer' : 'Créer le séjour'),
              ),
              if (_editing) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('openStayPageButton'),
                  onPressed: _busy ? null : _openStay,
                  icon: const Icon(Icons.cabin_outlined),
                  label: const Text('Ouvrir la page du séjour'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
