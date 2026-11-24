import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/questions.dto.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_questions.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/occurrence_actions.dart';
import 'package:lecoteaufleuri/ui/pages/questions/question_category_picker.dart';
import 'package:lecoteaufleuri/ui/pages/questions/questions_display.dart';

/// Les catégories de questions du séjour, que la direction crée, renomme et
/// supprime (leurs questions restent, sans catégorie).
class QuestionCategoriesPage extends ConsumerWidget {
  final String stayId;

  const QuestionCategoriesPage({super.key, required this.stayId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(questionCategoriesControllerProvider(stayId));
    final controller = ref.read(
      questionCategoriesControllerProvider(stayId).notifier,
    );
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addCategory'),
        onPressed: () => createCategory(context, ref, stayId),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle catégorie'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(
                'Pour ranger les questions du séjour. Toute l\'équipe y classe '
                'les siennes ; vous en créez aussi en posant une question.',
                style: muted,
              ),
              const SizedBox(height: 16),
              if (categories.value?.isEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Aucune catégorie.',
                    textAlign: TextAlign.center,
                    style: muted,
                  ),
                ),
              for (final c in categories.value ?? const <QuestionCategoryDto>[])
                Card(
                  key: Key('categoryRow-${c.id}'),
                  child: ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text(c.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Renommer',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => CategoryNameDialog(
                              title: 'Renommer la catégorie',
                              action: 'Renommer',
                              initial: c.name,
                              onSubmit: (name) async => (
                                value: true,
                                error: await controller.rename(c.id, name),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Supprimer',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final sure = await confirm(
                              context,
                              title: 'Supprimer « ${c.name} » ?',
                              content: 'Ses questions restent, sans catégorie.',
                              action: 'Supprimer',
                            );
                            if (!sure) return;
                            final error = await controller.delete(c.id);
                            if (error != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(questionsErrorMessage(error)),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
