import 'package:lecoteaufleuri/core/domain/exceptions/questions.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/questions.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/services/questions.repository.dart';

/// Le compte connecté, vu des questions : de quoi décider de ses droits.
typedef QuestionsViewer = ({String id, bool isAdmin});

/// Questions en mémoire (dev sans serveur, tests), avec les règles de l'API
/// (`ACCES.md`, « Questions du séjour ») : la direction voit tout, un
/// animateur les publiques et les siennes ; répondent la direction et
/// l'auteur ; une question anonyme tait son auteur aux autres animateurs ;
/// supprimer est réversible, seul un directeur efface pour de bon.
class InMemoryQuestionsRepository implements QuestionsRepository {
  final QuestionsViewer Function() _viewer;
  final StaffRole? Function(String stayId, String accountId) _roleOf;
  final QuestionAuthor? Function(String accountId) _authorOf;
  final DateTime Function() _now;
  final Map<String, _StoredQuestion> _questions = {};
  final Map<String, _StoredReply> _replies = {};
  final Map<String, ({String stayId, String name})> _categories = {};
  int _created = 0;

  /// Avec [demo], quelques questions sur l'été 2027 de démo.
  InMemoryQuestionsRepository({
    required QuestionsViewer Function() viewer,
    required StaffRole? Function(String stayId, String accountId) roleOf,
    QuestionAuthor? Function(String accountId)? authorOf,
    DateTime Function()? now,
    bool demo = false,
  }) : _viewer = viewer,
       _roleOf = roleOf,
       _authorOf = authorOf ?? ((_) => null),
       _now = now ?? DateTime.now {
    if (demo) _seed();
  }

  /// L'été 2027 de démo (10-24 juillet), dirigé par Dominique Durand.
  static const demoStayId = '5d1e0000-0000-4000-8000-000000000001';
  static const _dominique = '0a5c0000-0000-4000-8000-000000000101';
  static const _sacha = '0a5c0000-0000-4000-8000-000000000102';

  void _seed() {
    final now = _now();
    final safety = _nextId('c1');
    final daily = _nextId('c1');
    _categories[safety] = (stayId: demoStayId, name: 'Sécurité');
    _categories[daily] = (stayId: demoStayId, name: 'Vie quotidienne');

    String question(
      String author,
      String title, {
      String body = '',
      String? category,
      QuestionVisibility visibility = QuestionVisibility.private,
      bool anonymous = false,
      bool resolved = false,
      required Duration ago,
    }) {
      final id = _nextId('0e57');
      final at = now.subtract(ago);
      _questions[id] = _StoredQuestion(
        id: id,
        stayId: demoStayId,
        authorId: author,
        categoryId: category,
        title: title,
        body: body,
        visibility: visibility,
        anonymous: anonymous,
        resolvedAt: resolved ? at : null,
        createdAt: at,
        updatedAt: at,
      );
      return id;
    }

    void reply(String question, String author, String body, Duration ago) {
      final id = _nextId('0e58');
      final at = now.subtract(ago);
      _replies[id] = _StoredReply(
        id: id,
        questionId: question,
        authorId: author,
        body: body,
        createdAt: at,
        updatedAt: at,
      );
    }

    final kit = question(
      _dominique,
      'Où est la trousse de secours ?',
      body: 'Pour les sorties à la journée.',
      category: safety,
      visibility: QuestionVisibility.public,
      resolved: true,
      ago: const Duration(days: 2),
    );
    reply(
      kit,
      _dominique,
      'Dans le bureau, étagère du haut. Une par groupe.',
      const Duration(days: 2),
    );
    final night = question(
      _sacha,
      'Peut-on veiller le soir du feu de camp ?',
      category: daily,
      visibility: QuestionVisibility.public,
      anonymous: true,
      ago: const Duration(hours: 20),
    );
    reply(night, _dominique, 'Oui, jusqu\'à 23 h.', const Duration(hours: 18));
    reply(night, _sacha, 'Merci !', const Duration(hours: 17));
    question(
      _dominique,
      'Budget des sorties : où en est-on ?',
      body: 'À voir avec la trésorière avant jeudi.',
      ago: const Duration(hours: 5),
    );
  }

  @override
  Future<List<Question>> questions(String stayId) async {
    final role = _require(stayId);
    final me = _viewer().id;
    final direction = _isDirection(role);
    final list = [
      for (final q in _questions.values)
        if (q.stayId == stayId &&
            q.deletedAt == null &&
            (direction ||
                q.visibility == QuestionVisibility.public ||
                q.authorId == me))
          q,
    ]..sort((a, b) => _lastActivity(b).compareTo(_lastActivity(a)));
    return [for (final q in list) _view(q, role, withReplies: false)];
  }

  @override
  Future<List<Question>> deleted(String stayId) async {
    final role = _require(stayId, direction: true);
    final list = [
      for (final q in _questions.values)
        if (q.stayId == stayId && q.deletedAt != null) q,
    ]..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
    return [for (final q in list) _view(q, role, withReplies: false)];
  }

  @override
  Future<Question> question(String stayId, String questionId) async {
    final role = _require(stayId);
    return _view(_visible(stayId, questionId, role), role);
  }

  @override
  Future<Question> ask(
    String stayId, {
    required String title,
    String body = '',
    String? categoryId,
    QuestionVisibility visibility = QuestionVisibility.private,
  }) async {
    final role = _require(stayId);
    if (visibility == QuestionVisibility.public && !_isDirection(role)) {
      throw const QuestionsException(QuestionsErrorCode.forbidden);
    }
    _category(stayId, categoryId);
    final now = _now();
    final id = _nextId('0e57');
    _questions[id] = _StoredQuestion(
      id: id,
      stayId: stayId,
      authorId: _viewer().id,
      categoryId: categoryId,
      title: _title(title),
      body: _body(body),
      visibility: visibility,
      createdAt: now,
      updatedAt: now,
    );
    return _view(_questions[id]!, role);
  }

  @override
  Future<Question> edit(
    String stayId,
    String questionId, {
    required String title,
    String body = '',
  }) async {
    final role = _require(stayId);
    final q = _alive(_visible(stayId, questionId, role));
    _mustBeAuthor(q.authorId);
    q
      ..title = _title(title)
      ..body = _body(body)
      ..updatedAt = _now();
    return _view(q, role);
  }

  @override
  Future<Question> classify(
    String stayId,
    String questionId,
    String? categoryId,
  ) async {
    final role = _require(stayId);
    final q = _alive(_visible(stayId, questionId, role));
    if (q.authorId != _viewer().id && !_isDirection(role)) {
      throw const QuestionsException(QuestionsErrorCode.forbidden);
    }
    _category(stayId, categoryId);
    q.categoryId = categoryId;
    return _view(q, role);
  }

  @override
  Future<Question> show(
    String stayId,
    String questionId,
    QuestionVisibility visibility, {
    bool anonymous = false,
  }) async {
    final role = _require(stayId, direction: true);
    final q = _alive(_found(stayId, questionId));
    q
      ..visibility = visibility
      ..anonymous =
          visibility == QuestionVisibility.public &&
          anonymous &&
          !_isDirection(_roleOf(stayId, q.authorId), admin: false);
    return _view(q, role);
  }

  @override
  Future<Question> resolve(
    String stayId,
    String questionId,
    bool resolved,
  ) async {
    final role = _require(stayId, direction: true);
    final q = _alive(_found(stayId, questionId));
    q.resolvedAt = resolved ? (q.resolvedAt ?? _now()) : null;
    return _view(q, role);
  }

  @override
  Future<void> delete(String stayId, String questionId) async {
    final role = _require(stayId);
    final q = _alive(_visible(stayId, questionId, role));
    _mustBeAuthorOrDirection(q.authorId, role);
    q.deletedAt = _now();
  }

  @override
  Future<Question> restore(String stayId, String questionId) async {
    final role = _require(stayId, direction: true);
    final q = _found(stayId, questionId)..deletedAt = null;
    return _view(q, role);
  }

  @override
  Future<void> purge(String stayId, String questionId) async {
    _requireDirector(stayId);
    final q = _found(stayId, questionId);
    _questions.remove(q.id);
    _replies.removeWhere((_, r) => r.questionId == q.id);
  }

  @override
  Future<Question> reply(String stayId, String questionId, String body) async {
    final role = _require(stayId);
    final q = _alive(_visible(stayId, questionId, role));
    if (q.authorId != _viewer().id && !_isDirection(role)) {
      throw const QuestionsException(QuestionsErrorCode.forbidden);
    }
    final now = _now();
    final id = _nextId('0e58');
    _replies[id] = _StoredReply(
      id: id,
      questionId: q.id,
      authorId: _viewer().id,
      body: _replyBody(body),
      createdAt: now,
      updatedAt: now,
    );
    return _view(q, role);
  }

  @override
  Future<Question> editReply(
    String stayId,
    String questionId,
    String replyId,
    String body,
  ) async {
    final role = _require(stayId);
    final q = _alive(_visible(stayId, questionId, role));
    final r = _reply(q, replyId, withDeleted: false);
    _mustBeAuthor(r.authorId);
    r
      ..body = _replyBody(body)
      ..updatedAt = _now();
    return _view(q, role);
  }

  @override
  Future<Question> deleteReply(
    String stayId,
    String questionId,
    String replyId,
  ) async {
    final role = _require(stayId);
    final q = _alive(_visible(stayId, questionId, role));
    final r = _reply(q, replyId, withDeleted: false);
    _mustBeAuthorOrDirection(r.authorId, role);
    r.deletedAt = _now();
    return _view(q, role);
  }

  @override
  Future<Question> restoreReply(
    String stayId,
    String questionId,
    String replyId,
  ) async {
    final role = _require(stayId, direction: true);
    final q = _alive(_found(stayId, questionId));
    _reply(q, replyId, withDeleted: true).deletedAt = null;
    return _view(q, role);
  }

  @override
  Future<Question> purgeReply(
    String stayId,
    String questionId,
    String replyId,
  ) async {
    final role = _requireDirector(stayId);
    final q = _found(stayId, questionId);
    _replies.remove(_reply(q, replyId, withDeleted: true).id);
    return _view(q, role);
  }

  @override
  Future<List<QuestionCategory>> categories(String stayId) async {
    _require(stayId);
    return [
      for (final MapEntry(:key, :value) in _categories.entries)
        if (value.stayId == stayId) QuestionCategory(id: key, name: value.name),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<QuestionCategory> createCategory(String stayId, String name) async {
    _require(stayId, direction: true);
    final clean = _categoryName(stayId, name, except: null);
    final id = _nextId('c1');
    _categories[id] = (stayId: stayId, name: clean);
    return QuestionCategory(id: id, name: clean);
  }

  @override
  Future<QuestionCategory> renameCategory(
    String stayId,
    String categoryId,
    String name,
  ) async {
    _require(stayId, direction: true);
    _category(stayId, categoryId);
    final clean = _categoryName(stayId, name, except: categoryId);
    _categories[categoryId] = (stayId: stayId, name: clean);
    return QuestionCategory(id: categoryId, name: clean);
  }

  @override
  Future<void> deleteCategory(String stayId, String categoryId) async {
    _require(stayId, direction: true);
    _category(stayId, categoryId);
    _categories.remove(categoryId);
    for (final q in _questions.values) {
      if (q.categoryId == categoryId) q.categoryId = null;
    }
  }

  /// Le rôle de l'appelant dans le séjour (null pour un admin sans rôle) ;
  /// sans lien, le séjour n'existe pas pour lui.
  StaffRole? _require(String stayId, {bool direction = false}) {
    final viewer = _viewer();
    final role = _roleOf(stayId, viewer.id);
    if (role == null && !viewer.isAdmin) {
      throw const QuestionsException(QuestionsErrorCode.stayNotFound);
    }
    if (direction && !_isDirection(role)) {
      throw const QuestionsException(QuestionsErrorCode.forbidden);
    }
    return role;
  }

  StaffRole? _requireDirector(String stayId) {
    final role = _require(stayId);
    if (!_viewer().isAdmin && role != StaffRole.director) {
      throw const QuestionsException(QuestionsErrorCode.forbidden);
    }
    return role;
  }

  bool _isDirection(StaffRole? role, {bool admin = true}) =>
      (admin && _viewer().isAdmin) ||
      role == StaffRole.director ||
      role == StaffRole.deputy;

  _StoredQuestion _found(String stayId, String questionId) =>
      switch (_questions[questionId]) {
        final q? when q.stayId == stayId => q,
        _ => throw const QuestionsException(
          QuestionsErrorCode.questionNotFound,
        ),
      };

  _StoredQuestion _visible(String stayId, String questionId, StaffRole? role) {
    final q = _found(stayId, questionId);
    if (_isDirection(role)) return q;
    if (q.deletedAt != null ||
        (q.visibility == QuestionVisibility.private &&
            q.authorId != _viewer().id)) {
      throw const QuestionsException(QuestionsErrorCode.questionNotFound);
    }
    return q;
  }

  static _StoredQuestion _alive(_StoredQuestion q) => q.deletedAt == null
      ? q
      : throw const QuestionsException(QuestionsErrorCode.questionNotFound);

  _StoredReply _reply(
    _StoredQuestion q,
    String replyId, {
    required bool withDeleted,
  }) => switch (_replies[replyId]) {
    final r?
        when r.questionId == q.id && (withDeleted || r.deletedAt == null) =>
      r,
    _ => throw const QuestionsException(QuestionsErrorCode.replyNotFound),
  };

  void _category(String stayId, String? categoryId) {
    if (categoryId != null && _categories[categoryId]?.stayId != stayId) {
      throw const QuestionsException(QuestionsErrorCode.categoryNotFound);
    }
  }

  void _mustBeAuthor(String authorId) {
    final viewer = _viewer();
    if (!viewer.isAdmin && authorId != viewer.id) {
      throw const QuestionsException(QuestionsErrorCode.forbidden);
    }
  }

  void _mustBeAuthorOrDirection(String authorId, StaffRole? role) {
    if (authorId != _viewer().id && !_isDirection(role)) {
      throw const QuestionsException(QuestionsErrorCode.forbidden);
    }
  }

  String _categoryName(String stayId, String name, {required String? except}) {
    final clean = name.trim();
    if (clean.isEmpty || clean.length > 60) {
      throw const QuestionsException(QuestionsErrorCode.invalidCategory);
    }
    final taken = _categories.entries.any(
      (c) =>
          c.key != except &&
          c.value.stayId == stayId &&
          c.value.name.toLowerCase() == clean.toLowerCase(),
    );
    if (taken) {
      throw const QuestionsException(QuestionsErrorCode.categoryAlreadyExists);
    }
    return clean;
  }

  static String _title(String title) {
    final clean = title.trim();
    if (clean.isEmpty || clean.length > 200) {
      throw const QuestionsException(QuestionsErrorCode.invalidQuestion);
    }
    return clean;
  }

  static String _body(String body) {
    final clean = body.trim();
    if (clean.length > 5000) {
      throw const QuestionsException(QuestionsErrorCode.invalidQuestion);
    }
    return clean;
  }

  static String _replyBody(String body) {
    final clean = body.trim();
    if (clean.isEmpty || clean.length > 5000) {
      throw const QuestionsException(QuestionsErrorCode.invalidReply);
    }
    return clean;
  }

  List<_StoredReply> _thread(
    String questionId, {
    required bool withDeleted,
  }) => [
    for (final r in _replies.values)
      if (r.questionId == questionId && (withDeleted || r.deletedAt == null)) r,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  DateTime _lastActivity(_StoredQuestion q) {
    final alive = _thread(q.id, withDeleted: false);
    return alive.isEmpty || !alive.last.createdAt.isAfter(q.createdAt)
        ? q.createdAt
        : alive.last.createdAt;
  }

  /// La question telle que l'API la rendrait à l'appelant.
  Question _view(
    _StoredQuestion q,
    StaffRole? role, {
    bool withReplies = true,
  }) {
    final me = _viewer().id;
    final hidden = q.anonymous && !_isDirection(role) && q.authorId != me;
    final replies = _thread(q.id, withDeleted: _isDirection(role));
    return Question(
      id: q.id,
      categoryId: q.categoryId,
      title: q.title,
      body: q.body,
      visibility: q.visibility,
      anonymous: q.anonymous,
      author: hidden ? null : _authorOf(q.authorId),
      mine: q.authorId == me,
      resolvedAt: q.resolvedAt,
      createdAt: q.createdAt,
      updatedAt: q.updatedAt,
      deletedAt: q.deletedAt,
      replyCount: replies.where((r) => r.deletedAt == null).length,
      lastActivityAt: _lastActivity(q),
      replies: withReplies
          ? [
              for (final r in replies)
                QuestionReply(
                  id: r.id,
                  body: r.body,
                  author: hidden && r.authorId == q.authorId
                      ? null
                      : _authorOf(r.authorId),
                  mine: r.authorId == me,
                  createdAt: r.createdAt,
                  updatedAt: r.updatedAt,
                  deletedAt: r.deletedAt,
                ),
            ]
          : null,
    );
  }

  String _nextId(String prefix) =>
      '${prefix.padRight(8, '0')}-0000-4000-8000-${(++_created).toString().padLeft(12, '0')}';
}

class _StoredQuestion {
  final String id;
  final String stayId;
  final String authorId;
  String? categoryId;
  String title;
  String body;
  QuestionVisibility visibility;
  bool anonymous;
  DateTime? resolvedAt;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;

  _StoredQuestion({
    required this.id,
    required this.stayId,
    required this.authorId,
    this.categoryId,
    required this.title,
    required this.body,
    required this.visibility,
    this.anonymous = false,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });
}

class _StoredReply {
  final String id;
  final String questionId;
  final String authorId;
  String body;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;

  _StoredReply({
    required this.id,
    required this.questionId,
    required this.authorId,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });
}
