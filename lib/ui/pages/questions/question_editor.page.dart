import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/questions.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/questions.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/questions.dart';
import 'package:lecoteaufleuri/infrastructure/providers/question_thread.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_questions.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/questions/question_category_picker.dart';
import 'package:lecoteaufleuri/ui/pages/questions/questions_display.dart';

/// Poser une question ([editing] nul) ou modifier la sienne.
///
/// La direction choisit la visibilité en la posant ; la question d'un
/// animateur naît privée, entre lui et la direction. La catégorie se choisit
/// parmi celles du séjour ; la direction en crée à la volée.
class QuestionEditorPage extends ConsumerStatefulWidget {
  final String stayId;
  final QuestionsRights rights;
  final QuestionDto? editing;

  const QuestionEditorPage({
    super.key,
    required this.stayId,
    required this.rights,
    this.editing,
  });

  @override
  ConsumerState<QuestionEditorPage> createState() => _QuestionEditorPageState();
}

class _QuestionEditorPageState extends ConsumerState<QuestionEditorPage> {
  late final _title = TextEditingController(text: widget.editing?.title);
  late final _body = TextEditingController(text: widget.editing?.body);
  String? _categoryId;
  var _visibility = QuestionVisibility.private;
  var _saving = false;
  QuestionsErrorCode? _error;

  bool get _creating => widget.editing == null;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final QuestionsErrorCode? error;
    QuestionDto? created;
    if (_creating) {
      final outcome = await ref
          .read(stayQuestionsControllerProvider(widget.stayId).notifier)
          .ask(
            title: _title.text,
            body: _body.text,
            categoryId: _categoryId,
            visibility: _visibility,
          );
      error = outcome.error;
      created = outcome.question;
    } else {
      error = await ref
          .read(
            questionThreadControllerProvider(
              widget.stayId,
              widget.editing!.id,
            ).notifier,
          )
          .edit(title: _title.text, body: _body.text);
    }
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final canSubmit = _title.text.trim().isNotEmpty && !_saving;

    return Scaffold(
      appBar: AppBar(
        title: Text(_creating ? 'Poser une question' : 'Modifier la question'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                key: const Key('questionTitle'),
                controller: _title,
                autofocus: true,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Par exemple : où ranger le matériel de sport ?',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('questionBody'),
                controller: _body,
                minLines: 3,
                maxLines: 8,
                maxLength: 5000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Précisions (facultatif)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (_creating) ...[
                const SizedBox(height: 8),
                QuestionCategoryPicker(
                  stayId: widget.stayId,
                  selected: _categoryId,
                  canCreate: widget.rights.direction,
                  onChanged: (id) => setState(() => _categoryId = id),
                ),
                const SizedBox(height: 16),
                if (widget.rights.direction) ...[
                  Text('Visibilité', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<QuestionVisibility>(
                    key: const Key('questionVisibility'),
                    segments: const [
                      ButtonSegment(
                        value: QuestionVisibility.private,
                        icon: Icon(Icons.lock_outline),
                        label: Text('Privée'),
                      ),
                      ButtonSegment(
                        value: QuestionVisibility.public,
                        icon: Icon(Icons.public),
                        label: Text('Publique'),
                      ),
                    ],
                    selected: {_visibility},
                    onSelectionChanged: (s) =>
                        setState(() => _visibility = s.single),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _visibility == QuestionVisibility.private
                        ? 'Seuls les directeurs et adjoints la voient.'
                        : 'Toute l\'équipe du séjour la lit, avec ses réponses.',
                    style: muted,
                  ),
                ] else
                  Text(
                    'Votre question part à la direction : elle seule la voit '
                    'et y répond. Elle pourra la partager avec l\'équipe, en '
                    'taisant votre nom si elle le choisit.',
                    style: muted,
                  ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  questionsErrorMessage(_error!),
                  key: const Key('questionError'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const Key('submitQuestion'),
                  onPressed: canSubmit ? _submit : null,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_creating ? Icons.send : Icons.check),
                  label: Text(_creating ? 'Poser la question' : 'Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
