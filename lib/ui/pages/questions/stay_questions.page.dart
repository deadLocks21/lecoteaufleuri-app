import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/questions.dto.dart';
import 'package:lecoteaufleuri/core/application/session_state.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/questions.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_questions.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/questions/deleted_questions.page.dart';
import 'package:lecoteaufleuri/ui/pages/questions/question_categories.page.dart';
import 'package:lecoteaufleuri/ui/pages/questions/question_editor.page.dart';
import 'package:lecoteaufleuri/ui/pages/questions/question_thread.page.dart';
import 'package:lecoteaufleuri/ui/pages/questions/questions_display.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay_space_view.dart';
import 'package:lecoteaufleuri/ui/shell/app_shell.dart';

/// Ce que montre la liste : toutes les questions, celles qui attendent une
/// réponse de la direction, ou les résolues.
enum _Filter { all, open, resolved }

/// Le module Questions d'un séjour (cf. `ACCES.md`, « Questions du
/// séjour ») : les questions qu'on voit (toutes pour la direction, les
/// publiques et les siennes pour un animateur), la plus récemment active
/// d'abord, à filtrer par état et par catégorie. Toute l'équipe en pose ;
/// la direction gère aussi les catégories et les questions supprimées.
class StayQuestionsPage extends ConsumerStatefulWidget {
  final String stayId;

  const StayQuestionsPage({super.key, required this.stayId});

  @override
  ConsumerState<StayQuestionsPage> createState() => _StayQuestionsPageState();
}

class _StayQuestionsPageState extends ConsumerState<StayQuestionsPage> {
  var _filter = _Filter.all;
  String? _category;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final isAdmin = session is Authenticated && session.session.user.isAdmin;
    final stayId = widget.stayId;

    return StaySpaceView(
      stayId: stayId,
      builder: (context, space) {
        final rights = QuestionsRights.of(space, isAdmin: isAdmin);
        final questions = ref.watch(stayQuestionsControllerProvider(stayId));
        final categories =
            ref.watch(questionCategoriesControllerProvider(stayId)).value ??
            const <QuestionCategoryDto>[];
        final names = {for (final c in categories) c.id: c.name};

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: shellShowsBack(context),
            title: const Text('Questions'),
            actions: [
              if (rights.direction) ...[
                IconButton(
                  key: const Key('manageCategories'),
                  tooltip: 'Catégories',
                  icon: const Icon(Icons.label_outline),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QuestionCategoriesPage(stayId: stayId),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('deletedQuestions'),
                  tooltip: 'Questions supprimées',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          DeletedQuestionsPage(stayId: stayId, rights: rights),
                    ),
                  ),
                ),
              ],
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('askQuestion'),
            onPressed: () async {
              final created = await Navigator.of(context).push<QuestionDto>(
                MaterialPageRoute(
                  builder: (_) =>
                      QuestionEditorPage(stayId: stayId, rights: rights),
                ),
              );
              if (created != null && context.mounted) {
                _open(context, created, rights);
              }
            },
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Poser une question'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: switch ((questions.value, questions.error)) {
                (final List<QuestionDto> list, _) => RefreshIndicator(
                  onRefresh: () {
                    ref.invalidate(
                      questionCategoriesControllerProvider(stayId),
                    );
                    return ref.refresh(
                      stayQuestionsControllerProvider(stayId).future,
                    );
                  },
                  child: _list(context, list, names, categories, rights),
                ),
                (_, final Object error) => _ErrorView(
                  code: error is QuestionsException
                      ? error.code
                      : QuestionsErrorCode.unknown,
                  onRetry: () =>
                      ref.invalidate(stayQuestionsControllerProvider(stayId)),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _list(
    BuildContext context,
    List<QuestionDto> all,
    Map<String, String> names,
    List<QuestionCategoryDto> categories,
    QuestionsRights rights,
  ) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final shown = [
      for (final q in all)
        if ((_category == null || q.categoryId == _category) &&
            switch (_filter) {
              _Filter.all => true,
              _Filter.open => !q.isResolved,
              _Filter.resolved => q.isResolved,
            })
          q,
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          rights.direction
              ? 'Vos questions privées restent entre directeurs et adjoints ; '
                    'les publiques, toute l\'équipe les lit. Les animateurs '
                    'vous posent les leurs.'
              : 'Les questions partagées par la direction, et les vôtres : '
                    'elles partent à la direction, qui y répond.',
          style: muted,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (filter, label) in const [
                (_Filter.all, 'Toutes'),
                (_Filter.open, 'En attente'),
                (_Filter.resolved, 'Résolues'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: Key('filter-${filter.name}'),
                    label: Text(label),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 24, child: VerticalDivider(width: 16)),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      key: Key('category-${c.id}'),
                      label: Text(c.name),
                      selected: _category == c.id,
                      onSelected: (on) =>
                          setState(() => _category = on ? c.id : null),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              all.isEmpty
                  ? 'Aucune question pour l\'instant.'
                  : 'Aucune question ici.',
              key: const Key('noQuestions'),
              textAlign: TextAlign.center,
              style: muted,
            ),
          ),
        for (final q in shown)
          _QuestionTile(
            question: q,
            categoryName: names[q.categoryId],
            onTap: () => _open(context, q, rights),
            onResolve: rights.direction
                ? () => _resolve(context, q, !q.isResolved)
                : null,
          ),
      ],
    );
  }

  Future<void> _resolve(
    BuildContext context,
    QuestionDto q,
    bool resolved,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await ref
        .read(stayQuestionsControllerProvider(widget.stayId).notifier)
        .resolve(q.id, resolved);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error != null
              ? questionsErrorMessage(error)
              : resolved
              ? 'Question résolue.'
              : 'Question rouverte.',
        ),
        action: error == null
            ? SnackBarAction(
                label: 'Annuler',
                onPressed: () => ref
                    .read(
                      stayQuestionsControllerProvider(widget.stayId).notifier,
                    )
                    .resolve(q.id, !resolved),
              )
            : null,
      ),
    );
  }

  void _open(BuildContext context, QuestionDto q, QuestionsRights rights) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuestionThreadPage(
            stayId: widget.stayId,
            questionId: q.id,
            rights: rights,
          ),
        ),
      );
}

class _QuestionTile extends StatelessWidget {
  final QuestionDto question;
  final String? categoryName;
  final VoidCallback onTap;

  /// Marque résolue ou rouvre d'un geste (la direction) ; null : pas de bouton.
  final VoidCallback? onResolve;

  const _QuestionTile({
    required this.question,
    required this.categoryName,
    required this.onTap,
    this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final replies = switch (question.replyCount) {
      0 => 'Sans réponse',
      1 => '1 réponse',
      final n => '$n réponses',
    };
    return Card(
      key: Key('question-${question.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      question.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (onResolve != null)
                    IconButton(
                      key: Key('quickResolve-${question.id}'),
                      visualDensity: VisualDensity.compact,
                      tooltip: question.isResolved
                          ? 'Rouvrir'
                          : 'Marquer résolue',
                      onPressed: onResolve,
                      isSelected: question.isResolved,
                      selectedIcon: Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                    )
                  else if (question.isResolved)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.check_circle,
                        size: 20,
                        color: theme.colorScheme.primary,
                        semanticLabel: 'Résolue',
                      ),
                    ),
                ],
              ),
              if (question.body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  question.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 10),
              QuestionBadges(question: question, categoryName: categoryName),
              const SizedBox(height: 8),
              Text(
                '${questionAuthorLabel(question)} · $replies · '
                '${displayWhenAgo(question.lastActivityAt)}',
                style: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final QuestionsErrorCode code;
  final VoidCallback onRetry;

  const _ErrorView({required this.code, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            questionsErrorMessage(code),
            key: const Key('questionsError'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}
