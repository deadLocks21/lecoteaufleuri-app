import 'package:flutter/material.dart';
import 'package:lecoteaufleuri/core/application/dtos/questions.dto.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/questions.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';
import 'package:lecoteaufleuri/ui/pages/stays/stay_modules.dart';

/// Message affiché pour chaque échec autour des questions d'un séjour.
String questionsErrorMessage(QuestionsErrorCode code) => switch (code) {
  QuestionsErrorCode.forbidden =>
    'Vous n\'avez pas (ou plus) accès à cette action.',
  QuestionsErrorCode.stayNotFound =>
    'Ce séjour n\'existe plus, ou vous n\'y avez plus accès.',
  QuestionsErrorCode.questionNotFound =>
    'Cette question n\'existe plus, ou vous ne la voyez plus.',
  QuestionsErrorCode.replyNotFound => 'Cette réponse n\'existe plus.',
  QuestionsErrorCode.categoryNotFound => 'Cette catégorie n\'existe plus.',
  QuestionsErrorCode.invalidQuestion =>
    'Donnez un titre (200 caractères au plus) ; le texte en compte 5 000 au '
        'plus.',
  QuestionsErrorCode.invalidReply =>
    'Écrivez une réponse (5 000 caractères au plus).',
  QuestionsErrorCode.invalidCategory =>
    'Donnez un nom à la catégorie (60 caractères au plus).',
  QuestionsErrorCode.categoryAlreadyExists =>
    'Une catégorie porte déjà ce nom.',
  QuestionsErrorCode.sessionExpired => 'Votre session a expiré.',
  QuestionsErrorCode.network =>
    'Connexion au serveur impossible. Vérifiez votre réseau.',
  QuestionsErrorCode.badServerUrl =>
    'Le serveur ne répond pas comme l\'API Le Coteau Fleuri.',
  QuestionsErrorCode.unknown => 'Une erreur est survenue. Réessayez.',
};

/// Ce que l'appelant peut faire des questions du séjour ouvert : un choix
/// d'écran, l'API décide (cf. `ACCES.md`, « Questions du séjour »).
class QuestionsRights {
  /// L'admin, un directeur ou un adjoint : voit tout, répond à tout, modère.
  final bool direction;

  /// L'admin ou un directeur : efface pour de bon.
  final bool purges;
  final bool isAdmin;

  const QuestionsRights({
    required this.direction,
    required this.purges,
    required this.isAdmin,
  });

  factory QuestionsRights.of(StaySpaceDto space, {required bool isAdmin}) =>
      QuestionsRights(
        direction: isDirection(space, isAdmin: isAdmin),
        purges: isAdmin || space.role == StaffRole.director,
        isAdmin: isAdmin,
      );

  bool canReply(QuestionDto q) => direction || q.mine;
  bool canEdit(QuestionDto q) => q.mine || isAdmin;
  bool canClassify(QuestionDto q) => direction || q.mine;
  bool canDelete(QuestionDto q) => direction || q.mine;
  bool canEditReply(QuestionReplyDto r) => r.mine || isAdmin;
  bool canDeleteReply(QuestionReplyDto r) => direction || r.mine;
}

/// Qui a posé la question : son nom, « Un animateur » quand l'API le tait.
String questionAuthorLabel(QuestionDto q) =>
    q.authorName ?? (q.anonymous ? 'Un animateur' : 'Compte supprimé');

/// Qui a écrit la réponse ; sans nom, c'est l'auteur d'une question anonyme.
String replyAuthorLabel(QuestionReplyDto r, QuestionDto q) =>
    r.authorName ?? (q.anonymous ? 'Un animateur' : 'Compte supprimé');

/// `il y a 5 min`, `hier`, ou le jour.
String displayWhenAgo(DateTime at, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(at);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 2) return 'hier';
  return 'le ${displayShortDay(at.toLocal())}';
}

/// Une pastille : la visibilité, l'anonymat, l'état d'une question.
class QuestionBadges extends StatelessWidget {
  final QuestionDto question;
  final String? categoryName;

  const QuestionBadges({super.key, required this.question, this.categoryName});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget badge(IconData icon, String label, {Color? color, Key? key}) => Chip(
      key: key,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      side: BorderSide(color: scheme.outlineVariant),
    );
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (question.isPublic)
          badge(Icons.public, 'Publique', key: const Key('publicBadge'))
        else
          badge(Icons.lock_outline, 'Privée', key: const Key('privateBadge')),
        if (question.anonymous)
          badge(
            Icons.visibility_off_outlined,
            'Anonyme',
            key: const Key('anonymousBadge'),
          ),
        if (question.isResolved)
          badge(
            Icons.check_circle,
            'Résolue',
            color: scheme.primary,
            key: const Key('resolvedBadge'),
          ),
        if (categoryName != null) badge(Icons.label_outline, categoryName!),
      ],
    );
  }
}
