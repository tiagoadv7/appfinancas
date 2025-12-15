import '../models/user.dart';

abstract class AuthService {
  /// Attempts to sign in the user and returns the authenticated [User], or null.
  Future<User?> signIn();

  /// Signs out the current user.
  Future<void> signOut();

  /// Returns the current signed in user, if any.
  User? get currentUser;
}
