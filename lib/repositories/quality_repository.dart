import 'dart:typed_data';

import 'package:smart_app/core/api_service.dart';
import 'package:smart_app/model/quality_record.dart';

class QualityRepository {
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
  }) async {
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
    } catch (_) {
      return QualityAnalysisRecord.localEstimate(
        imageName: imageUrl.split('/').last,
        byteLength: imageUrl.length * 97,
      );
    }
  }

  Future<void> saveInspection({
    required int procurementItemId,
    required String imageUrl,
    required String ownerConfirmedGrade,
    required String ownerDecision,
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
        },
        parser: (_) {},
      );
    } catch (_) {
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
