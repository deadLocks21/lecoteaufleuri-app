import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/questions.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/questions.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_questions.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/questions/question_thread.page.dart';
import 'package:lecoteaufleuri/ui/pages/questions/questions_display.dart';

/// Les questions supprimées du séjour, que seule la direction voit : on les
/// ouvre pour les restaurer, ou (un directeur) les supprimer définitivement.
class DeletedQuestionsPage extends ConsumerWidget {
  final String stayId;
  final QuestionsRights rights;

  const DeletedQuestionsPage({
    super.key,
    required this.stayId,
    required this.rights,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleted = ref.watch(deletedQuestionsProvider(stayId));
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Questions supprimées')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: switch ((deleted.value, deleted.error)) {
            (final List<QuestionDto> list, _) => RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(deletedQuestionsProvider(stayId).future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    rights.purges
                        ? 'Elles ont disparu pour l\'équipe. Ouvrez-en une pour '
                              'la restaurer ou la supprimer définitivement.'
                        : 'Elles ont disparu pour l\'équipe. Ouvrez-en une pour '
                              'la restaurer ; seul un directeur les efface pour '
                              'de bon.',
                    style: muted,
                  ),
                  const SizedBox(height: 16),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Aucune question supprimée.',
                        key: const Key('noDeletedQuestions'),
                        textAlign: TextAlign.center,
                        style: muted,
                      ),
                    ),
                  for (final q in list)
                    Card(
                      key: Key('deleted-${q.id}'),
                      child: ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: Text(q.title),
                        subtitle: Text(
                          '${questionAuthorLabel(q)} · supprimée '
                          '${displayWhenAgo(q.deletedAt!)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => QuestionThreadPage(
                              stayId: stayId,
                              questionId: q.id,
                              rights: rights,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            (_, final Object error) => Center(
              child: Text(
                questionsErrorMessage(
                  error is QuestionsException
                      ? error.code
                      : QuestionsErrorCode.unknown,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}
