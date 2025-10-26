enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? token;

  AuthState({this.status = AuthStatus.unknown, this.token});

  AuthState copyWith({AuthStatus? status, String? token}) {
    return AuthState(status: status ?? this.status, token: token ?? this.token);
  }
}
