import '../models/app_user.dart';

class AuthService {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  /// Log in with a display name — creates a local-only user.
  AppUser login(String name) {
    _currentUser = AppUser(
      uid: 'local_user',
      email: 'local@device',
      displayName: name,
    );
    return _currentUser!;
  }

  void signOut() {
    _currentUser = null;
  }
}
