import 'package:smart_app/core/api_service.dart';

class AuthLoginResult {
  const AuthLoginResult({
    required this.accessToken,
    required this.tokenType,
    required this.role,
  });

  final String accessToken;
  final String tokenType;
  final String role;
}

class CurrentUser {
  const CurrentUser({
    required this.accountId,
    required this.email,
    required this.role,
    required this.status,
    required this.emailVerified,
  });

  final int accountId;
  final String email;
  final String role;
  final String status;
  final bool emailVerified;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      accountId: _asInt(json['account_id']),
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      emailVerified: json['email_verified'] == true,
    );
  }
}

class AuthRepository {
  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) {
    return ApiService.postData<AuthLoginResult>(
      '/auth/login',
      body: {'email': email, 'password': password},
      parser: (data) {
        final json = data as Map<String, dynamic>? ?? const {};
        return AuthLoginResult(
          accessToken: json['access_token']?.toString() ?? '',
          tokenType: json['token_type']?.toString() ?? 'bearer',
          role: json['role']?.toString() ?? '',
        );
      },
    );
  }

  Future<CurrentUser> fetchMe() {
    return ApiService.getData<CurrentUser>(
      '/me',
      requiresAuth: true,
      parser: (data) {
        final json = data as Map<String, dynamic>? ?? const {};
        return CurrentUser.fromJson(json);
      },
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
