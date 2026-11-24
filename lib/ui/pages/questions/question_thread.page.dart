import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/questions.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/questions.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/questions.dart';
import 'package:lecoteaufleuri/infrastructure/providers/question_thread.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_questions.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/occurrence_actions.dart';
import 'package:lecoteaufleuri/ui/pages/questions/question_category_picker.dart';
import 'package:lecoteaufleuri/ui/pages/questions/question_editor.page.dart';
import 'package:lecoteaufleuri/ui/pages/questions/questions_display.dart';

/// Une question et son fil (cf. `ACCES.md`, « Questions du séjour »).
/// Répondent la direction et l'auteur de la question ; chacun modifie ses
/// messages ; la direction la rend publique (nommée ou anonyme) ou privée,
/// la marque résolue, supprime (de façon réversible) ce qu'il faut ; un
/// directeur efface pour de bon.
class QuestionThreadPage extends ConsumerStatefulWidget {
  final String stayId;
  final String questionId;
  final QuestionsRights rights;

  const QuestionThreadPage({
    super.key,
    required this.stayId,
    required this.questionId,
    required this.rights,
  });

  @override
  ConsumerState<QuestionThreadPage> createState() => _QuestionThreadPageState();
}

class _QuestionThreadPageState extends ConsumerState<QuestionThreadPage> {
  final _reply = TextEditingController();
  var _sending = false;

  QuestionThreadControllerProvider get _provider =>
      questionThreadControllerProvider(widget.stayId, widget.questionId);
  QuestionThreadController get _controller => ref.read(_provider.notifier);

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  /// Lance [action] ; sur un échec, le dit. Vrai si elle a réussi.
  Future<bool> _do(Future<QuestionsErrorCode?> Function() action) async {
    final error = await action();
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(questionsErrorMessage(error))));
    }
    return error == null;
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final ok = await _do(() => _controller.reply(_reply.text));
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) _reply.clear();
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(_provider);
    final rights = widget.rights;
    final question = thread.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
        actions: [
          if (question != null && !question.isDeleted && rights.direction)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: question.isResolved
                  ? OutlinedButton.icon(
                      key: const Key('resolveButton'),
                      onPressed: () => _do(() => _controller.resolve(false)),
                      icon: const Icon(Icons.replay),
                      label: const Text('Rouvrir'),
                    )
                  : FilledButton.tonalIcon(
                      key: const Key('resolveButton'),
                      onPressed: () => _do(() => _controller.resolve(true)),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Résolue'),
                    ),
            ),
          if (question != null) _actions(context, question, rights),
        ],
      ),
      body: switch ((thread.value, thread.error)) {
        (final QuestionDto q, _) => Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: RefreshIndicator(
                    onRefresh: () => ref.refresh(_provider.future),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _Header(stayId: widget.stayId, question: q),
                        const SizedBox(height: 16),
                        if (q.replies?.isEmpty ?? true)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Pas encore de réponse.',
                              key: const Key('noReplies'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        for (final r in q.replies ?? const <QuestionReplyDto>[])
                          _ReplyCard(
                            question: q,
                            reply: r,
                            actions: _replyActions(context, q, r, rights),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (rights.canReply(q) && !q.isDeleted) _composer(context),
          ],
        ),
        (_, final Object error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              questionsErrorMessage(
                error is QuestionsException
                    ? error.code
                    : QuestionsErrorCode.unknown,
              ),
              key: const Key('threadError'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _composer(BuildContext context) => SafeArea(
    top: false,
    child: Material(
      elevation: 3,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('replyField'),
                    controller: _reply,
                    minLines: 1,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Répondre…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  key: const Key('sendReply'),
                  tooltip: 'Envoyer',
                  onPressed: _reply.text.trim().isEmpty || _sending
                      ? null
                      : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _actions(BuildContext context, QuestionDto q, QuestionsRights rights) {
    final items = <PopupMenuEntry<VoidCallback>>[
      if (!q.isDeleted && rights.canEdit(q))
        PopupMenuItem(
          key: const Key('editQuestion'),
          value: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => QuestionEditorPage(
                stayId: widget.stayId,
                rights: rights,
                editing: q,
              ),
            ),
          ),
          child: const ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Modifier'),
          ),
        ),
      if (!q.isDeleted && rights.canClassify(q))
        PopupMenuItem(
          key: const Key('classifyQuestion'),
          value: () => _classify(context, q, rights),
          child: const ListTile(
            leading: Icon(Icons.label_outline),
            title: Text('Classer'),
          ),
        ),
      if (!q.isDeleted && rights.direction) ...[
        PopupMenuItem(
          key: const Key('changeVisibility'),
          value: () => _changeVisibility(context, q),
          child: ListTile(
            leading: Icon(q.isPublic ? Icons.lock_outline : Icons.public),
            title: Text(q.isPublic ? 'Rendre privée' : 'Rendre publique…'),
          ),
        ),
      ],
      if (!q.isDeleted && rights.canDelete(q))
        PopupMenuItem(
          key: const Key('deleteQuestion'),
          value: () => _delete(context, q, rights),
          child: const ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Supprimer'),
          ),
        ),
      if (q.isDeleted && rights.direction)
        PopupMenuItem(
          key: const Key('restoreQuestion'),
          value: () => _do(_controller.restore),
          child: const ListTile(
            leading: Icon(Icons.restore_from_trash_outlined),
            title: Text('Restaurer'),
          ),
        ),
      if (rights.purges)
        PopupMenuItem(
          key: const Key('purgeQuestion'),
          value: () => _purge(context),
          child: ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Supprimer définitivement'),
          ),
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<VoidCallback>(
      key: const Key('questionActions'),
      tooltip: 'Actions',
      itemBuilder: (_) => items,
      onSelected: (action) => action(),
    );
  }

  Future<void> _classify(
    BuildContext context,
    QuestionDto q,
    QuestionsRights rights,
  ) async {
    final chosen = await showDialog<({String? id})>(
      context: context,
      builder: (context) {
        String? selected = q.categoryId;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Classer la question'),
            content: SizedBox(
              width: 360,
              child: QuestionCategoryPicker(
                stayId: widget.stayId,
                selected: selected,
                canCreate: rights.direction,
                onChanged: (id) => setState(() => selected = id),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              FilledButton(
                key: const Key('submitClassify'),
                onPressed: () => Navigator.of(context).pop((id: selected)),
                child: const Text('Classer'),
              ),
            ],
          ),
        );
      },
    );
    if (chosen != null) await _do(() => _controller.classify(chosen.id));
  }

  Future<void> _changeVisibility(BuildContext context, QuestionDto q) async {
    if (q.isPublic) {
      await _do(() => _controller.show(QuestionVisibility.private));
      return;
    }
    // La question d'un animateur peut taire son nom ; celle de la direction
    // reste nommée (l'API y veille).
    final anonymous = await showDialog<bool>(
      context: context,
      builder: (context) {
        var hidden = !q.mine;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Rendre publique'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toute l\'équipe du séjour lira la question et ses réponses.',
                ),
                if (!q.mine) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    key: const Key('anonymousSwitch'),
                    contentPadding: EdgeInsets.zero,
                    value: hidden,
                    onChanged: (v) => setState(() => hidden = v),
                    title: const Text('Taire le nom de l\'auteur'),
                    subtitle: Text(
                      hidden
                          ? 'Les autres animateurs liront « Un animateur ».'
                          : 'Son nom sera visible de toute l\'équipe.',
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              FilledButton(
                key: const Key('submitVisibility'),
                onPressed: () => Navigator.of(context).pop(hidden),
                child: const Text('Rendre publique'),
              ),
            ],
          ),
        );
      },
    );
    if (anonymous != null) {
      await _do(
        () => _controller.show(QuestionVisibility.public, anonymous: anonymous),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    QuestionDto q,
    QuestionsRights rights,
  ) async {
    final sure = await confirm(
      context,
      title: 'Supprimer la question ?',
      content: rights.direction
          ? 'Elle disparaît pour l\'équipe, avec ses réponses. Vous la '
                'retrouverez dans les questions supprimées.'
          : 'Elle disparaît, avec ses réponses. La direction pourra la '
                'restaurer.',
      action: 'Supprimer',
    );
    if (!sure || !context.mounted) return;
    if (await _do(_controller.delete) && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _purge(BuildContext context) async {
    final sure = await confirm(
      context,
      title: 'Supprimer définitivement ?',
      content:
          'La question et toutes ses réponses seront effacées. On ne pourra '
          'pas les retrouver.',
      action: 'Supprimer définitivement',
    );
    if (!sure || !context.mounted) return;
    if (await _do(_controller.purge) && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  List<PopupMenuEntry<VoidCallback>> _replyActions(
    BuildContext context,
    QuestionDto q,
    QuestionReplyDto r,
    QuestionsRights rights,
  ) => [
    if (!q.isDeleted && !r.deleted && rights.canEditReply(r))
      PopupMenuItem(
        key: const Key('editReply'),
        value: () => _editReply(context, r),
        child: const ListTile(
          leading: Icon(Icons.edit_outlined),
          title: Text('Modifier'),
        ),
      ),
    if (!q.isDeleted && !r.deleted && rights.canDeleteReply(r))
      PopupMenuItem(
        key: const Key('deleteReply'),
        value: () => _do(() => _controller.deleteReply(r.id)),
        child: const ListTile(
          leading: Icon(Icons.delete_outline),
          title: Text('Supprimer'),
        ),
      ),
    if (!q.isDeleted && r.deleted && rights.direction)
      PopupMenuItem(
        key: const Key('restoreReply'),
        value: () => _do(() => _controller.restoreReply(r.id)),
        child: const ListTile(
          leading: Icon(Icons.restore_from_trash_outlined),
          title: Text('Restaurer'),
        ),
      ),
    if (r.deleted && rights.purges)
      PopupMenuItem(
        key: const Key('purgeReply'),
        value: () async {
          final sure = await confirm(
            context,
            title: 'Supprimer définitivement ?',
            content: 'Cette réponse sera effacée pour de bon.',
            action: 'Supprimer définitivement',
          );
          if (sure) await _do(() => _controller.purgeReply(r.id));
        },
        child: const ListTile(
          leading: Icon(Icons.delete_forever_outlined),
          title: Text('Supprimer définitivement'),
        ),
      ),
  ];

  Future<void> _editReply(BuildContext context, QuestionReplyDto r) async {
    final text = TextEditingController(text: r.body);
    final body = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la réponse'),
        content: SizedBox(
          width: 480,
          child: TextField(
            key: const Key('replyEditField'),
            controller: text,
            autofocus: true,
            minLines: 2,
            maxLines: 8,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('submitReplyEdit'),
            onPressed: () => Navigator.of(context).pop(text.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    text.dispose();
    if (body != null) await _do(() => _controller.editReply(r.id, body));
  }
}

class _Header extends ConsumerWidget {
  final String stayId;
  final QuestionDto question;

  const _Header({required this.stayId, required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final categories =
        ref.watch(questionCategoriesControllerProvider(stayId)).value ??
        const <QuestionCategoryDto>[];
    final category = categories
        .where((c) => c.id == question.categoryId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.isDeleted)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              key: const Key('deletedBanner'),
              color: theme.colorScheme.errorContainer,
              child: const ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Question supprimée'),
                subtitle: Text(
                  'Seule la direction la voit. Restaurez-la depuis le menu.',
                ),
              ),
            ),
          ),
        Text(
          question.title,
          key: const Key('questionTitleText'),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          '${questionAuthorLabel(question)} · '
          '${displayWhenAgo(question.createdAt)}'
          '${question.edited ? ' · modifiée' : ''}',
          key: const Key('questionAuthor'),
          style: muted,
        ),
        if (question.body.isNotEmpty) ...[
          const SizedBox(height: 12),
          SelectableText(question.body, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: 12),
        QuestionBadges(question: question, categoryName: category?.name),
        const Divider(height: 32),
      ],
    );
  }
}

class _ReplyCard extends StatelessWidget {
  final QuestionDto question;
  final QuestionReplyDto reply;
  final List<PopupMenuEntry<VoidCallback>> actions;

  const _ReplyCard({
    required this.question,
    required this.reply,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Opacity(
      opacity: reply.deleted ? 0.55 : 1,
      child: Card(
        key: Key('reply-${reply.id}'),
        margin: const EdgeInsets.only(bottom: 10),
        color: reply.mine
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${replyAuthorLabel(reply, question)} · '
                      '${displayWhenAgo(reply.createdAt)}'
                      '${reply.edited ? ' · modifiée' : ''}'
                      '${reply.deleted ? ' · supprimée' : ''}',
                      style: muted,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      reply.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: reply.deleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (actions.isNotEmpty)
                PopupMenuButton<VoidCallback>(
                  key: Key('replyActions-${reply.id}'),
                  tooltip: 'Actions',
                  itemBuilder: (_) => actions,
                  onSelected: (action) => action(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
