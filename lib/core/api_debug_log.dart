import 'package:flutter/foundation.dart';

class ApiDebugLog {
  ApiDebugLog._();

  static void request(
    String method,
    Uri uri, {
    required bool requiresAuth,
    String? token,
  }) {
    if (!kDebugMode) return;
    final auth = !requiresAuth
        ? 'auth=none'
        : token == null || token.isEmpty
        ? 'auth=missing'
        : 'auth=Bearer ${_redactToken(token)}';
    debugPrint('[API 요청] $method $uri $auth');
  }

  static void response(String method, Uri uri, int statusCode) {
    if (!kDebugMode) return;
    debugPrint('[API 응답] $method $uri status=$statusCode');
  }

  static void ok(String scope, String message) {
    if (!kDebugMode) return;
    debugPrint('[API 정상][$scope] $message');
  }

  static void fallback(String scope, Object error, {String? message}) {
    if (!kDebugMode) return;
    final suffix = message == null || message.isEmpty ? '' : ' $message';
    debugPrint('[API 폴백][$scope]$suffix error=$error');
  }

  static void fallbackReason(String scope, String message) {
    if (!kDebugMode) return;
    debugPrint('[API 폴백][$scope] $message');
  }

  static String _redactToken(String token) {
    if (token.length <= 3) return '...';
    if (token.length <= 12) return '${token.substring(0, 3)}...';
    return '${token.substring(0, 6)}...${token.substring(token.length - 4)}';
  }
}
