import 'api_client.dart';
import 'session_store.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final SessionUser user;
}

class AuthService {
  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/auth/register',
      authenticated: false,
      body: <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
    return _toSession(data);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/auth/login',
      authenticated: false,
      body: <String, dynamic>{
        'email': email.trim(),
        'password': password,
      },
    );
    return _toSession(data);
  }

  AuthSession _toSession(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw Exception('Response autentikasi tidak valid.');
    }
    final token = data['access_token']?.toString() ?? '';
    final userJson = data['user'];
    if (token.isEmpty || userJson is! Map<String, dynamic>) {
      throw Exception('Data login tidak lengkap.');
    }

    final session = AuthSession(
      accessToken: token,
      user: SessionUser.fromJson(userJson),
    );
    SessionStore.setSession(token: session.accessToken, sessionUser: session.user);
    return session;
  }
}
