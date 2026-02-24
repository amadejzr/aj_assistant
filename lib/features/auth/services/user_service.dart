import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_user.dart';

class UserService {
  static const _keyUid = 'user_uid';
  static const _keyName = 'user_name';

  final FlutterSecureStorage _storage;

  UserService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<AppUser?> getUser() async {
    final uid = await _storage.read(key: _keyUid);
    final name = await _storage.read(key: _keyName);
    if (uid == null || name == null) return null;
    return AppUser(uid: uid, email: 'local@device', displayName: name);
  }

  Future<void> createUser(AppUser user) async {
    await _storage.write(key: _keyUid, value: user.uid);
    await _storage.write(key: _keyName, value: user.displayName ?? 'User');
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: _keyUid);
    await _storage.delete(key: _keyName);
  }
}
