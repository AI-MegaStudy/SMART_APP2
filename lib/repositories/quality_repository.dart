import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:smart_app/core/api_debug_log.dart';
import 'package:smart_app/core/api_service.dart';
import 'package:smart_app/model/quality_record.dart';

class QualityRepository {
  static const String dlQualityApiUrl = String.fromEnvironment(
    'DL_QUALITY_API_URL',
    defaultValue:
        'https://imbecile-plow-unboxed.ngrok-free.dev/owner/quality-inspections',
  );
  static const Duration dlQualityTimeout = Duration(seconds: 60);

  Future<List<QualityTargetRecord>> fetchInspectionTargets() async {
    try {
      final records = await ApiService.getData<List<QualityTargetRecord>>(
        '/owner/procurements',
        requiresAuth: true,
        parser: (data) {
          final list = data as List<dynamic>? ?? const [];
          final records = <QualityTargetRecord>[];
          for (final item in list) {
            final json = item as Map<String, dynamic>? ?? const {};
            if (_isApproved(json)) {
              records.add(QualityTargetRecord.fromProcurementJson(json));
            }
          }
          return records.where((item) => item.procurementItemId > 0).toList();
        },
      );
      return records.isEmpty ? _fallbackTargets() : records;
    } catch (_) {
      return _fallbackTargets();
    }
  }

  Future<QualityImageUploadRecord> uploadImage({
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    try {
      return await ApiService.postMultipartData<QualityImageUploadRecord>(
        '/owner/quality-inspections/image',
        requiresAuth: true,
        fileField: 'file',
        fileName: fileName,
        fileBytes: fileBytes,
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return QualityImageUploadRecord.fromJson(json);
        },
      );
    } catch (_) {
      return QualityImageUploadRecord(imageUrl: 'local://$fileName');
    }
  }

  Future<QualityAnalysisRecord> analyzeImage({
    required int procurementItemId,
    required String imageUrl,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final external = await _analyzeWithExternalDl(
      imageUrl: imageUrl,
      fileName: fileName,
      fileBytes: fileBytes,
    );
    if (external != null) return external;

    try {
      return await ApiService.postData<QualityAnalysisRecord>(
        '/owner/quality-inspections/analyze',
        requiresAuth: true,
        body: {
          'procurement_item_id': procurementItemId,
          'image_url': imageUrl,
          'persist_image': false,
        },
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return QualityAnalysisRecord.fromJson(json);
        },
      );
    } catch (error) {
      ApiDebugLog.fallback(
        'quality.backend',
        error,
        message: '백엔드 신선도 분석 실패. 앱 내부 보조 판정을 사용합니다.',
      );
      return QualityAnalysisRecord.localEstimate(
        imageName: imageUrl.split('/').last,
        byteLength: imageUrl.length * 97,
      );
    }
  }

  Future<QualityAnalysisRecord?> _analyzeWithExternalDl({
    required String imageUrl,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    if (dlQualityApiUrl.trim().isEmpty) {
      ApiDebugLog.fallbackReason(
        'quality.dl',
        'DL_QUALITY_API_URL이 비어 있어 외부 DL 분석을 건너뜁니다.',
      );
      return null;
    }
    try {
      final request = http.MultipartRequest('POST', Uri.parse(dlQualityApiUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          fileBytes,
          filename: fileName,
          contentType: _contentType(fileName),
        ),
      );
      final streamed = await request.send().timeout(dlQualityTimeout);
      final response = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
      final payload = decoded is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>? ?? decoded
          : const <String, dynamic>{};
      final record = QualityAnalysisRecord.fromJson({
        ...payload,
        if ((payload['image_url']?.toString() ?? '').isEmpty)
          'image_url': imageUrl,
      });
      ApiDebugLog.ok(
        'quality.dl',
        'url=$dlQualityApiUrl result=grade=${record.modelGrade}, '
            'freshness=${record.freshnessScore}, color=${record.colorScore}, '
            'roundness=${record.roundnessScore}, bruise=${record.bruiseProbability}, '
            'decision=${record.modelDecision}, model=${record.modelVersion}',
      );
      return record;
    } catch (error) {
      ApiDebugLog.fallback(
        'quality.dl',
        error,
        message: '외부 DL 분석 실패. 백엔드 분석으로 전환합니다.',
      );
      return null;
    }
  }

  Future<void> saveInspection({
    required int procurementItemId,
    required String imageUrl,
    required String ownerConfirmedGrade,
    required String ownerDecision,
    required QualityAnalysisRecord analysis,
  }) async {
    try {
      await ApiService.postData<void>(
        '/owner/quality-inspections',
        requiresAuth: true,
        body: {
          'procurement_item_id': procurementItemId,
          'image_url': imageUrl,
          'owner_confirmed_grade': ownerConfirmedGrade,
          'owner_decision': ownerDecision,
          'model_grade': analysis.modelGrade,
          'freshness_score': analysis.freshnessScore,
          'color_score': analysis.colorScore,
          'roundness_score': analysis.roundnessScore,
          'bruise_probability': analysis.bruiseProbability,
          'model_decision': analysis.modelDecision,
          'model_version': analysis.modelVersion,
        },
        parser: (_) {},
      );
      ApiDebugLog.ok(
        'quality.save',
        'procurementItem=$procurementItemId grade=${analysis.modelGrade}, '
            'decision=$ownerDecision, image=$imageUrl',
      );
    } catch (error) {
      ApiDebugLog.fallback(
        'quality.save',
        error,
        message: '신선도 저장 API 실패. 화면 흐름만 유지합니다.',
      );
      return;
    }
  }

  static bool _isApproved(Map<String, dynamic> json) {
    final status = json['procurement_status']?.toString() ?? '';
    return status == 'APPROVED' || status == 'PARTIAL_APPROVED';
  }

  List<QualityTargetRecord> _fallbackTargets() {
    return const [
      QualityTargetRecord(
        procurementId: 9901,
        procurementItemId: 990101,
        orderId: 99001,
        customerName: '김민지',
        productName: '양광 사과',
        packageCount: 2,
        requestedKg: 10,
        isFallback: true,
      ),
      QualityTargetRecord(
        procurementId: 9902,
        procurementItemId: 990201,
        orderId: 99002,
        customerName: '박서준',
        productName: '부사 사과',
        packageCount: 1,
        requestedKg: 3,
        isFallback: true,
      ),
    ];
  }
}

MediaType _contentType(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.webp')) return MediaType('image', 'webp');
  return MediaType('image', 'jpeg');
}
