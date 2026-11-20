import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/news.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/infrastructure/news/in_memory.news.repository.dart';

void main() {
  const stayId = '5d1e0000-0000-4000-8000-000000000001';
  const director = 'director';
  const animator = 'animator';
  const otherAnimator = 'other';
  const stranger = 'stranger';
  final stay = Stay(
    id: stayId,
    name: 'Été 2027',
    kind: StayKind.acm,
    startsOn: DateTime.utc(2027, 7, 10),
    endsOn: DateTime.utc(2027, 7, 24),
  );
  const roles = {
    director: StaffRole.director,
    animator: StaffRole.animator,
    otherAnimator: StaffRole.animator,
  };
  final photo = PickedPhoto(name: 'p.png', bytes: Uint8List.fromList([1]));

  late String viewer;
  late DateTime now;
  late InMemoryNewsRepository news;

  setUp(() {
    viewer = director;
    now = DateTime.utc(2027, 7, 12, 12);
    news = InMemoryNewsRepository(
      viewer: () => (id: viewer, isAdmin: false),
      roleOf: (stay, account) => stay == stayId ? roles[account] : null,
      stayOf: (id) => id == stayId ? stay : null,
      now: () => now,
    );
  });

  Matcher failsWith(NewsErrorCode expected) =>
      throwsA(isA<NewsException>().having((e) => e.code, 'code', expected));

  Future<StayPhoto> uploadAs(String account) async {
    viewer = account;
    final uploaded = await news.upload(stayId, photo);
    now = now.add(const Duration(minutes: 1));
    return uploaded;
  }

  test('un animateur ne voit que ses photos, la direction toutes', () async {
    final mine = await uploadAs(animator);
    await uploadAs(otherAnimator);

    viewer = animator;
    expect((await news.photos(stayId)).map((p) => p.id), [mine.id]);
    viewer = director;
    expect(await news.photos(stayId), hasLength(2));
    viewer = stranger;
    await expectLater(
      news.photos(stayId),
      failsWith(NewsErrorCode.stayNotFound),
    );
  });

  test(
    'la pioche montre les retenues d\'abord, les écartées en dernier',
    () async {
      final discarded = await uploadAs(animator);
      final pending = await uploadAs(animator);
      final kept = await uploadAs(animator);
      viewer = director;
      await news.sort(stayId, discarded.id, PhotoSorting.discarded);
      await news.sort(stayId, kept.id, PhotoSorting.kept);

      expect((await news.photos(stayId)).map((p) => p.id), [
        kept.id,
        pending.id,
        discarded.id,
      ]);
    },
  );

  test('un animateur ne trie pas les photos d\'un autre', () async {
    final theirs = await uploadAs(otherAnimator);

    viewer = animator;
    await expectLater(
      news.sort(stayId, theirs.id, PhotoSorting.kept),
      failsWith(NewsErrorCode.photoNotFound),
    );
    await expectLater(news.days(stayId), failsWith(NewsErrorCode.forbidden));
  });

  test('un jour par date, comprise dans le séjour', () async {
    await news.createDay(stayId, DateTime.utc(2027, 7, 12));

    await expectLater(
      news.createDay(stayId, DateTime.utc(2027, 7, 12)),
      failsWith(NewsErrorCode.dayAlreadyExists),
    );
    await expectLater(
      news.createDay(stayId, DateTime.utc(2027, 7, 25)),
      failsWith(NewsErrorCode.invalidDayDate),
    );
  });

  test(
    'une photo n\'illustre qu\'un jour, et un jour vide ne se publie pas',
    () async {
      final picked = await uploadAs(animator);
      viewer = director;
      final first = await news.createDay(stayId, DateTime.utc(2027, 7, 11));
      final second = await news.createDay(stayId, DateTime.utc(2027, 7, 12));

      await expectLater(
        news.publishDay(stayId, first.id),
        failsWith(NewsErrorCode.emptyDay),
      );
      await news.setDayPhotos(stayId, first.id, [picked.id]);
      await expectLater(
        news.setDayPhotos(stayId, second.id, [picked.id]),
        failsWith(NewsErrorCode.photoInAnotherDay),
      );
      expect((await news.photos(stayId)).single.dayId, first.id);
    },
  );

  test('un jour programmé paraît de lui-même à son heure', () async {
    final picked = await uploadAs(otherAnimator);
    viewer = director;
    final day = await news.createDay(stayId, DateTime.utc(2027, 7, 12));
    await news.setDayPhotos(stayId, day.id, [picked.id]);

    final scheduled = await news.publishDay(
      stayId,
      day.id,
      at: now.add(const Duration(hours: 6)),
    );
    expect(scheduled.status, DayStatus.scheduled);

    viewer = animator;
    expect(await news.news(stayId), isEmpty);
    await expectLater(
      news.image(stayId, picked.id, PhotoSize.large),
      failsWith(NewsErrorCode.photoNotFound),
    );

    now = now.add(const Duration(hours: 6));
    expect((await news.news(stayId)).single.id, day.id);
    expect(await news.image(stayId, picked.id, PhotoSize.large), photo.bytes);

    viewer = director;
    await news.unpublishDay(stayId, day.id);
    viewer = animator;
    expect(await news.news(stayId), isEmpty);
  });

  test('supprimer un jour rend ses photos à la pioche', () async {
    final picked = await uploadAs(animator);
    viewer = director;
    final day = await news.createDay(stayId, DateTime.utc(2027, 7, 12));
    await news.setDayPhotos(stayId, day.id, [picked.id]);

    await news.deleteDay(stayId, day.id);

    expect((await news.photos(stayId)).single.dayId, isNull);
  });
}
