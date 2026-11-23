import 'package:flutter/material.dart';

/// Sur quoi porte un changement fait depuis un jour d'une série.
enum SeriesScope { occurrence, series }

/// Demande, comme Google Agenda, si un changement vaut pour ce seul jour
/// ou pour toute la série ; null si l'on renonce.
///
/// Sans [occurrenceAllowed], seul « Tous les événements » se choisit, et
/// [note] dit pourquoi.
Future<SeriesScope?> askSeriesScope(
  BuildContext context, {
  required String title,
  bool occurrenceAllowed = true,
  String? note,
}) => showDialog<SeriesScope>(
  context: context,
  builder: (_) => _SeriesScopeDialog(
    title: title,
    occurrenceAllowed: occurrenceAllowed,
    note: note,
  ),
);

class _SeriesScopeDialog extends StatefulWidget {
  final String title;
  final bool occurrenceAllowed;
  final String? note;

  const _SeriesScopeDialog({
    required this.title,
    required this.occurrenceAllowed,
    required this.note,
  });

  @override
  State<_SeriesScopeDialog> createState() => _SeriesScopeDialogState();
}

class _SeriesScopeDialogState extends State<_SeriesScopeDialog> {
  late SeriesScope _scope = widget.occurrenceAllowed
      ? SeriesScope.occurrence
      : SeriesScope.series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
      content: RadioGroup<SeriesScope>(
        groupValue: _scope,
        onChanged: (scope) => setState(() => _scope = scope ?? _scope),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioListTile<SeriesScope>(
              key: const Key('scope-occurrence'),
              value: SeriesScope.occurrence,
              enabled: widget.occurrenceAllowed,
              title: const Text('Cet événement'),
            ),
            RadioListTile<SeriesScope>(
              key: const Key('scope-series'),
              value: SeriesScope.series,
              title: const Text('Tous les événements'),
            ),
            if (widget.note case final note?)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 0, 0),
                child: Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('confirmScope'),
          onPressed: () => Navigator.of(context).pop(_scope),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
