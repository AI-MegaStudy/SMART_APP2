import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:smart_app/core/api_debug_log.dart';
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
    final uri = _uri(path);
    _logRequest('GET', uri, requiresAuth: requiresAuth);
    final response = await http
        .get(uri, headers: _headers(requiresAuth: requiresAuth))
        .timeout(requestTimeout);
    ApiDebugLog.response('GET', uri, response.statusCode);

    return _decodeData(response, parser, requiresAuth: requiresAuth);
  }

  static Future<T> postData<T>(
    String path, {
    Object? body,
    T Function(Object? data)? parser,
    bool requiresAuth = false,
  }) async {
    final uri = _uri(path);
    _logRequest('POST', uri, requiresAuth: requiresAuth);
    final response = await http
        .post(
          uri,
          headers: _headers(requiresAuth: requiresAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(requestTimeout);
    ApiDebugLog.response('POST', uri, response.statusCode);

    return _decodeData(response, parser, requiresAuth: requiresAuth);
  }

  static Future<T> putData<T>(
    String path, {
    Object? body,
    T Function(Object? data)? parser,
    bool requiresAuth = false,
  }) async {
    final uri = _uri(path);
    _logRequest('PUT', uri, requiresAuth: requiresAuth);
    final response = await http
        .put(
          uri,
          headers: _headers(requiresAuth: requiresAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(requestTimeout);
    ApiDebugLog.response('PUT', uri, response.statusCode);

    return _decodeData(response, parser, requiresAuth: requiresAuth);
  }

  static Future<T> patchData<T>(
    String path, {
    Object? body,
    T Function(Object? data)? parser,
    bool requiresAuth = false,
  }) async {
    final uri = _uri(path);
    _logRequest('PATCH', uri, requiresAuth: requiresAuth);
    final response = await http
        .patch(
          uri,
          headers: _headers(requiresAuth: requiresAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(requestTimeout);
    ApiDebugLog.response('PATCH', uri, response.statusCode);

    return _decodeData(response, parser, requiresAuth: requiresAuth);
  }

  static Future<T> postMultipartData<T>(
    String path, {
    required String fileField,
    required String fileName,
    required Uint8List fileBytes,
    required T Function(Object? data) parser,
    Map<String, String> fields = const {},
    bool requiresAuth = false,
  }) async {
    final uri = _uri(path);
    _logRequest('POST', uri, requiresAuth: requiresAuth);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(
      _headers(requiresAuth: requiresAuth)..remove('Content-Type'),
    );
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
        contentType: _imageContentType(fileName),
      ),
    );

    final streamed = await request.send().timeout(requestTimeout);
    final response = await http.Response.fromStream(streamed);
    ApiDebugLog.response('POST', uri, response.statusCode);
    return _decodeData(response, parser, requiresAuth: requiresAuth);
  }

  static Uri _uri(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  static MediaType? _imageContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'gif' => MediaType('image', 'gif'),
      'webp' => MediaType('image', 'webp'),
      _ => null,
    };
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

  static Future<T> _decodeData<T>(
    http.Response response,
    T Function(Object? data)? parser, {
    required bool requiresAuth,
  }) async {
    final decoded = _decodeJson(response);
    final message = decoded['message']?.toString() ?? '요청 처리에 실패했습니다.';

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (requiresAuth && response.statusCode == 401) {
        await AuthSession.clear();
      }
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

  static void _logRequest(
    String method,
    Uri uri, {
    required bool requiresAuth,
  }) {
    ApiDebugLog.request(
      method,
      uri,
      requiresAuth: requiresAuth,
      token: requiresAuth ? AuthSession.accessToken : null,
    );
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
      'verification request not found' => '인증번호 발송 내역을 찾을 수 없습니다.',
      'verification code already used' => '이미 사용한 인증번호입니다.',
      'verification code expired' => '인증번호가 만료되었습니다.',
      'verification attempts exceeded' => '인증번호 입력 횟수를 초과했습니다.',
      'invalid verification code' => '인증번호를 확인해주세요.',
      'verification resend cooldown' => '잠시 후 인증번호를 다시 요청해주세요.',
      'product not found' => '상품 정보를 찾을 수 없습니다.',
      'farm not found' => '농장 정보를 찾을 수 없습니다.',
      'harvest slot not found' => '수확 슬롯 정보를 찾을 수 없습니다.',
      'procurement not found' => '발주 정보를 찾을 수 없습니다.',
      'return request not found' => '반품 요청 정보를 찾을 수 없습니다.',
      'unsupported image extension' =>
        '지원하지 않는 이미지 형식입니다. JPG 또는 PNG 이미지를 선택해주세요.',
      'invalid file name' => '이미지 파일명을 처리하지 못했습니다. 다른 이미지를 선택해주세요.',
      'image file too large' => '이미지 용량이 너무 큽니다. 더 작은 이미지를 선택해주세요.',
      'invalid image content type' => '이미지 파일 형식을 확인해주세요.',
      'invalid image file' => '이미지 파일을 읽을 수 없습니다. 다른 이미지를 선택해주세요.',
      'image_url must be uploaded image url' => '이미지 업로드가 완료된 뒤 저장할 수 있습니다.',
      'farm_image_url must be uploaded image url' =>
        '농장 이미지를 업로드한 뒤 저장할 수 있습니다.',
      'evidence_image_url must be uploaded image url' =>
        '고객 첨부 이미지는 업로드된 이미지 URL이어야 합니다.',
      'internal server error' => '서버에서 요청을 처리하지 못했습니다.',
      _ => message.isEmpty ? '요청을 처리하지 못했습니다.' : message,
    };
  }
}
