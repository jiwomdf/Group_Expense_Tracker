import 'package:core/domain/model/user_model.dart';

/// Separates "auth is not resolved yet" from "signed out".
///
/// Firebase emits its first auth event asynchronously while it restores the
/// persisted session, so treating the initial absence of a user as signed out
/// makes the app flash the login page on a cold start.
class AuthState {
  final UserModel? user;
  final bool isResolved;

  const AuthState._({this.user, required this.isResolved});

  const AuthState.unknown() : this._(isResolved: false);

  const AuthState.unauthenticated() : this._(isResolved: true);

  AuthState.authenticated(UserModel user) : this._(user: user, isResolved: true);

  bool get isAuthenticated => user != null;
}
