import 'package:flutter/foundation.dart';

class ApiDebugLog {
  ApiDebugLog._();

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
}
