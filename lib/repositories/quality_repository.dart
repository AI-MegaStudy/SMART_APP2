import 'dart:typed_data';

import 'package:smart_app/core/api_service.dart';
import 'package:smart_app/model/quality_record.dart';

class QualityRepository {
  Future<List<QualityTargetRecord>> fetchInspectionTargets() {
    return ApiService.getData<List<QualityTargetRecord>>(
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
  }

  Future<QualityImageUploadRecord> uploadImage({
    required String fileName,
    required Uint8List fileBytes,
  }) {
    return ApiService.postMultipartData<QualityImageUploadRecord>(
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
  }

  Future<QualityAnalysisRecord> analyzeImage({
    required int procurementItemId,
    required String imageUrl,
  }) {
    return ApiService.postData<QualityAnalysisRecord>(
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
  }

  Future<void> saveInspection({
    required int procurementItemId,
    required String imageUrl,
    required String ownerConfirmedGrade,
    required String ownerDecision,
  }) {
    return ApiService.postData<void>(
      '/owner/quality-inspections',
      requiresAuth: true,
      body: {
        'procurement_item_id': procurementItemId,
        'image_url': imageUrl,
        'owner_confirmed_grade': ownerConfirmedGrade,
        'owner_decision': ownerDecision,
      },
      parser: (_) {},
    );
  }

  static bool _isApproved(Map<String, dynamic> json) {
    final status = json['procurement_status']?.toString() ?? '';
    return status == 'APPROVED' || status == 'PARTIAL_APPROVED';
  }
}
