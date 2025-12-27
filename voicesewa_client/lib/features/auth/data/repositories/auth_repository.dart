import '../daos/db_login_dao.dart';

class AuthRepository {
  final DbLoginDao _dao;
  AuthRepository(this._dao);

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    await _dao.upsertUser(username: username, password: password, lastLoginAt: now);
  }

  Future<Map<String, dynamic>?> getLoggedInUser() async {
    return await _dao.getLoggedInUser();
  }

  Future<bool> isSessionValid({int days = 5}) async {
    final user = await _dao.getLoggedInUser();
    if (user == null) return false;
    final last = user['last_login_at'] as int;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return (now - last) <= days * 24 * 60 * 60;
  }

  Future<void> logout(String username) async {
    await _dao.logoutUser(username);
  }
}
