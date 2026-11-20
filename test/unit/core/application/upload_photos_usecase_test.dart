import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/application/usecases/news.usecases.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/news.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/services/photo_picker.service.dart';
import 'package:lecoteaufleuri/infrastructure/news/in_memory.news.repository.dart';

class _Picker implements PhotoPicker {
  final List<PickedPhoto> photos;

  _Picker(this.photos);

  @override
  Future<List<PickedPhoto>> pick() async => photos;
}

void main() {
  const stayId = '5d1e0000-0000-4000-8000-000000000001';
  final stay = Stay(
    id: stayId,
    name: 'Été 2027',
    kind: StayKind.acm,
    startsOn: DateTime.utc(2027, 7, 10),
    endsOn: DateTime.utc(2027, 7, 24),
  );
  InMemoryNewsRepository repository({bool linked = true}) =>
      InMemoryNewsRepository(
        viewer: () => (id: 'animator', isAdmin: false),
        roleOf: (_, _) => linked ? StaffRole.animator : null,
        stayOf: (_) => stay,
      );
  PickedPhoto photo(List<int> bytes) =>
      PickedPhoto(name: 'p.jpg', bytes: Uint8List.fromList(bytes));

  test('dépose les photos une à une en disant où en est l\'envoi', () async {
    final progress = <(int, int)>[];

    final report = await UploadPhotosUseCase(
      repository(),
      _Picker([
        photo([1]),
        photo([2]),
      ]),
    ).execute(stayId, onProgress: (sent, total) => progress.add((sent, total)));

    expect(report?.uploaded, hasLength(2));
    expect(report?.failed, 0);
    expect(progress, [(0, 2), (1, 2), (2, 2)]);
  });

  test('une photo refusée n\'arrête pas les suivantes', () async {
    final report = await UploadPhotosUseCase(
      repository(),
      _Picker([
        photo([]),
        photo([2]),
      ]),
    ).execute(stayId);

    expect(report?.uploaded, hasLength(1));
    expect(report?.failed, 1);
    expect(report?.error, NewsErrorCode.unsupportedPhoto);
  });

  test('sans accès au séjour, rien ne part', () async {
    final report = await UploadPhotosUseCase(
      repository(linked: false),
      _Picker([
        photo([1]),
        photo([2]),
        photo([3]),
      ]),
    ).execute(stayId);

    expect(report?.uploaded, isEmpty);
    expect(report?.failed, 3);
    expect(report?.error, NewsErrorCode.stayNotFound);
  });

  test('renoncer au choix ne dépose rien', () async {
    expect(
      await UploadPhotosUseCase(repository(), _Picker([])).execute(stayId),
      isNull,
    );
  });
}
