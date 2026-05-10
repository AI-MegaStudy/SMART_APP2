import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/core/auth_session.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );
  static const Duration requestTimeout = Duration(seconds: 8);

  static Future<T> getData<T>(
    String path, {
    T Function(Object? data)? parser,
    bool requiresAuth = false,
  }) async {
    final response = await http
        .get(_uri(path), headers: _headers(requiresAuth: requiresAuth))
        .timeout(requestTimeout);

    return _decodeData(response, parser);
  }

  static Future<T> postData<T>(
    String path, {
    Object? body,
    T Function(Object? data)? parser,
    bool requiresAuth = false,
  }) async {
    final response = await http
        .post(
          _uri(path),
          headers: _headers(requiresAuth: requiresAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(requestTimeout);

    return _decodeData(response, parser);
  }

  static Future<T> putData<T>(
    String path, {
    Object? body,
    T Function(Object? data)? parser,
    bool requiresAuth = false,
  }) async {
    final response = await http
        .put(
          _uri(path),
          headers: _headers(requiresAuth: requiresAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(requestTimeout);

    return _decodeData(response, parser);
  }

  static Future<T> patchData<T>(
    String path, {
    Object? body,
    T Function(Object? data)? parser,
    bool requiresAuth = false,
  }) async {
    final response = await http
        .patch(
          _uri(path),
          headers: _headers(requiresAuth: requiresAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(requestTimeout);

    return _decodeData(response, parser);
  }

  static Uri _uri(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  static Map<String, String> _headers({required bool requiresAuth}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = AuthSession.accessToken;
      if (token == null || token.isEmpty) {
        throw const ApiException(message: '로그인이 필요합니다.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static T _decodeData<T>(
    http.Response response,
    T Function(Object? data)? parser,
  ) {
    final decoded = _decodeJson(response);
    final message = decoded['message']?.toString() ?? '요청 처리에 실패했습니다.';

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: _toUserMessage(message),
        statusCode: response.statusCode,
        error: decoded['error'],
      );
    }

    final error = decoded['error'];
    if (error != null) {
      throw ApiException(
        message: _toUserMessage(message),
        statusCode: response.statusCode,
        error: error,
      );
    }

    final data = decoded['data'];
    if (parser != null) {
      return parser(data);
    }
    return data as T;
  }

  static Map<String, Object?> _decodeJson(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
    } catch (_) {
      throw ApiException(
        message: '응답을 읽을 수 없습니다.',
        statusCode: response.statusCode,
      );
    }

    throw ApiException(
      message: '응답을 읽을 수 없습니다.',
      statusCode: response.statusCode,
    );
  }

  static String _toUserMessage(String message) {
    return switch (message) {
      'validation failed' => '입력한 정보를 다시 확인해주세요.',
      'invalid email or password' => '이메일 또는 비밀번호를 확인해주세요.',
      'authentication required' => '로그인이 필요합니다.',
      'invalid access token' => '로그인이 만료되었습니다. 다시 로그인해주세요.',
      'account not found' => '계정 정보를 찾을 수 없습니다.',
      'forbidden' => '점주 권한으로만 접근할 수 있습니다.',
      'email already exists' => '이미 가입된 이메일입니다.',
      'email verification required' => '이메일 인증을 먼저 완료해주세요.',
      'product not found' => '상품 정보를 찾을 수 없습니다.',
      'farm not found' => '농장 정보를 찾을 수 없습니다.',
      'harvest slot not found' => '수확 슬롯 정보를 찾을 수 없습니다.',
      'procurement not found' => '발주 정보를 찾을 수 없습니다.',
      'return request not found' => '반품 요청 정보를 찾을 수 없습니다.',
      'internal server error' => '서버에서 요청을 처리하지 못했습니다.',
      _ => message.isEmpty ? '요청을 처리하지 못했습니다.' : message,
    };
  }
}
