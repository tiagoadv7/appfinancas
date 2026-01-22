import '../models/user.dart';

abstract class AuthService {
  /// Attempts to sign in the user with email and password and returns the authenticated [User], or null.
  Future<User?> signIn({String? email, String? password});

  /// Signs out the current user.
  Future<void> signOut();

  /// Returns the current signed in user, if any.
  User? get currentUser;
}
