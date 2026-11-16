import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';

final camille = User(
  id: '0a5c0000-0000-4000-8000-0000000000ff',
  phoneNumber: '+33612345678',
  firstName: 'Camille',
  lastName: 'Martin',
);

Session sessionExpiringAt(DateTime expiresAt) =>
    Session(token: 'jwt-token', expiresAt: expiresAt, user: camille);
