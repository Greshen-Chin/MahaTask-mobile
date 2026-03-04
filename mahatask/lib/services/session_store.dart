class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.email,
    this.userCode,
    this.bio,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? userCode;
  final String? bio;
  final String? avatarUrl;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      userCode: json['userCode']?.toString(),
      bio: json['bio']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class SessionStore {
  static String? accessToken;
  static SessionUser? user;

  static bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;

  static void setSession({
    required String token,
    required SessionUser sessionUser,
  }) {
    accessToken = token;
    user = sessionUser;
  }

  static void clear() {
    accessToken = null;
    user = null;
  }
}
