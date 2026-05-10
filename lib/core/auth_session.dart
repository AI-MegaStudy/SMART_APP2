import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  AuthSession._();

  static const _accessTokenKey = 'harvest_slot_owner_access_token';
  static const _roleKey = 'harvest_slot_owner_role';

  static String? accessToken;
  static String? role;

  static bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;

  static Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    accessToken = preferences.getString(_accessTokenKey);
    role = preferences.getString(_roleKey);
  }

  static Future<void> login({
    required String token,
    required String userRole,
  }) async {
    accessToken = token;
    role = userRole;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accessTokenKey, token);
    await preferences.setString(_roleKey, userRole);
  }

  static Future<void> logout() async {
    accessToken = null;
    role = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_roleKey);
  }
}
