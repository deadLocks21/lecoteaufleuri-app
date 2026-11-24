import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/questions.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/questions.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_questions.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/questions/questions_display.dart';

/// Le choix d'une catégorie du séjour, ou d'aucune. Avec [canCreate] (la
/// direction), « Nouvelle catégorie… » en crée une à la volée et la choisit.
class QuestionCategoryPicker extends ConsumerWidget {
  final String stayId;
  final String? selected;
  final bool canCreate;
  final ValueChanged<String?> onChanged;

  const QuestionCategoryPicker({
    super.key,
    required this.stayId,
    required this.selected,
    required this.canCreate,
    required this.onChanged,
  });

  static const _create = '__create__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(questionCategoriesControllerProvider(stayId)).value ??
        const <QuestionCategoryDto>[];
    return DropdownButtonFormField<String?>(
      key: const Key('questionCategory'),
      initialValue: categories.any((c) => c.id == selected) ? selected : null,
      decoration: const InputDecoration(
        labelText: 'Catégorie',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Sans catégorie')),
        for (final c in categories)
          DropdownMenuItem(value: c.id, child: Text(c.name)),
        if (canCreate)
          const DropdownMenuItem(
            key: Key('createCategory'),
            value: _create,
            child: Row(
              children: [
                Icon(Icons.add, size: 18),
                SizedBox(width: 8),
                Text('Nouvelle catégorie…'),
              ],
            ),
          ),
      ],
      onChanged: (value) async {
        if (value != _create) {
          onChanged(value);
          return;
        }
        final created = await createCategory(context, ref, stayId);
        onChanged(created?.id ?? selected);
      },
    );
  }
}

/// Demande un nom et crée la catégorie ; null si l'on renonce.
Future<QuestionCategoryDto?> createCategory(
  BuildContext context,
  WidgetRef ref,
  String stayId,
) => showDialog<QuestionCategoryDto>(
  context: context,
  builder: (_) => CategoryNameDialog(
    title: 'Nouvelle catégorie',
    action: 'Créer',
    onSubmit: (name) async {
      final outcome = await ref
          .read(questionCategoriesControllerProvider(stayId).notifier)
          .create(name);
      return (value: outcome.category, error: outcome.error);
    },
  ),
);

/// Un nom de catégorie à saisir ; le dialogue reste ouvert sur une erreur.
class CategoryNameDialog extends StatefulWidget {
  final String title;
  final String action;
  final String initial;
  final Future<({Object? value, QuestionsErrorCode? error})> Function(
    String name,
  )
  onSubmit;

  const CategoryNameDialog({
    super.key,
    required this.title,
    required this.action,
    this.initial = '',
    required this.onSubmit,
  });

  @override
  State<CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<CategoryNameDialog> {
  late final _name = TextEditingController(text: widget.initial);
  String? _error;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final outcome = await widget.onSubmit(_name.text);
    if (!mounted) return;
    if (outcome.error case final error?) {
      setState(() {
        _saving = false;
        _error = questionsErrorMessage(error);
      });
      return;
    }
    Navigator.of(context).pop(outcome.value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const Key('categoryName'),
      controller: _name,
      autofocus: true,
      maxLength: 60,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: 'Nom',
        errorText: _error,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _name.text.trim().isEmpty ? null : _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Annuler'),
      ),
      FilledButton(
        key: const Key('submitCategory'),
        onPressed: _name.text.trim().isEmpty || _saving ? null : _submit,
        child: Text(widget.action),
      ),
    ],
  );
}
