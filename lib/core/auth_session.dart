import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    _logSession('restore');
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
    _logSession('login');
  }

  static Future<void> logout() async {
    accessToken = null;
    role = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_roleKey);
  }

  static void _logSession(String event) {
    if (!kDebugMode) return;
    final token = accessToken;
    if (token == null || token.isEmpty) {
      debugPrint('[세션][$event] 저장된 토큰 없음');
      return;
    }

    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        debugPrint('[세션][$event] JWT 형식 아님');
        return;
      }
      final payloadText = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final payload = jsonDecode(payloadText) as Map<String, dynamic>;
      final exp = payload['exp'];
      final subject = payload['sub']?.toString() ?? '';
      final tokenRole = payload['role']?.toString() ?? role ?? '';
      final expiresAt = _parseJwtExp(exp);
      if (expiresAt == null) {
        debugPrint('[세션][$event] user=$subject role=$tokenRole exp=$exp');
        return;
      }
      final now = DateTime.now();
      final remaining = expiresAt.difference(now);
      debugPrint(
        '[세션][$event] user=$subject role=$tokenRole '
        'expiresAt=${expiresAt.toLocal().toIso8601String()} '
        'remaining=${_durationLabel(remaining)}',
      );
    } catch (error) {
      debugPrint('[세션][$event] 토큰 디코딩 실패 error=$error');
    }
  }

  static DateTime? _parseJwtExp(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
    }
    final seconds = int.tryParse(value?.toString() ?? '');
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  static String _durationLabel(Duration duration) {
    if (duration.isNegative) {
      return '만료됨 ${_durationLabel(-duration)} 전';
    }
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    if (days > 0) return '$days일 $hours시간';
    if (hours > 0) return '$hours시간 $minutes분';
    return '$minutes분';
  }
}
