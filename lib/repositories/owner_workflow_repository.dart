import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:smart_app/core/api_service.dart';
import 'package:smart_app/model/owner_order_record.dart';
import 'package:smart_app/model/owner_status_record.dart';

class OwnerWorkflowRepository {
  Future<List<OwnerOrderRecord>> fetchOrders() async {
    try {
      final orders = await ApiService.getData<List<OwnerOrderRecord>>(
        '/owner/orders',
        requiresAuth: true,
        parser: _parseOrders,
      );
      if (orders.isNotEmpty) return orders;
    } catch (_) {
      // Development fallback: keep owner flows usable while backend data is sparse.
    }
    return _loadMockOrders();
  }

  Future<List<OwnerProcurementRequestRecord>> fetchProcurementRequests() async {
    try {
      final records =
          await ApiService.getData<List<OwnerProcurementRequestRecord>>(
            '/owner/procurements',
            requiresAuth: true,
            parser: (data) {
              final list = data as List<dynamic>? ?? const [];
              return [
                for (final item in list)
                  OwnerProcurementRequestRecord.fromProcurementJson(
                    item as Map<String, dynamic>? ?? const {},
                  ),
              ];
            },
          );
      if (records.isNotEmpty) return records;
    } catch (_) {
      // Development fallback: order seed exists before procurement seed.
    }

    final orders = await fetchOrders();
    return [
      for (final order in orders)
        OwnerProcurementRequestRecord.fromOrder(order),
    ];
  }

  Future<bool> decideProcurement({
    required OwnerProcurementRequestRecord request,
    required String decision,
    String? rejectedReason,
    List<OwnerProcurementDecisionItem>? decisionItems,
  }) async {
    if (request.isFallback) return false;
    try {
      await ApiService.patchData<Map<String, dynamic>>(
        '/owner/procurements/${request.id}/decision',
        requiresAuth: true,
        body: {
          'decision': decision,
          'items': [
            for (final item in decisionItems ??
                [
                  for (final item in request.items)
                    OwnerProcurementDecisionItem(
                      procurementItemId: item.procurementItemId,
                      approvedPackageCount: decision == 'REJECTED'
                          ? 0
                          : item.requestedPackageCount,
                      approvedKg: decision == 'REJECTED' ? 0 : item.requestedKg,
                      ownerMemo: decision == 'REJECTED'
                          ? rejectedReason
                          : '정상 수량 확인',
                    ),
                ])
              {
                'procurement_item_id': item.procurementItemId,
                'approved_package_count': item.approvedPackageCount,
                'approved_kg': item.approvedKg,
                'owner_memo': item.ownerMemo,
              },
          ],
          'rejected_reason': rejectedReason,
        },
        parser: (data) => data as Map<String, dynamic>? ?? const {},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<OwnerProcurementRequestRecord>> fetchShippableProcurements() async {
    final records = await fetchProcurementRequests();
    return records
        .where(
          (record) =>
              !record.isFallback &&
              record.orderId != null &&
              record.orderId! > 0 &&
              (record.status == '승인') &&
              (record.shipmentStatus == null || record.shipmentStatus!.isEmpty),
        )
        .toList();
  }

  Future<bool> createShipment({
    required OwnerProcurementRequestRecord request,
    required String carrierName,
    required String trackingNo,
    required int shippedPackageCount,
    required double shippedKg,
  }) async {
    final orderId = request.orderId;
    if (request.isFallback || orderId == null || orderId <= 0) return false;
    try {
      await ApiService.postData<Map<String, dynamic>>(
        '/owner/shipments',
        requiresAuth: true,
        body: {
          'order_id': orderId,
          'carrier_name': carrierName,
          'tracking_no': trackingNo,
          'shipped_package_count': shippedPackageCount,
          'shipped_kg': shippedKg,
        },
        parser: (data) => data as Map<String, dynamic>? ?? const {},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  List<OwnerOrderRecord> _parseOrders(Object? data) {
    final list = data as List<dynamic>? ?? const [];
    return [
      for (final item in list)
        OwnerOrderRecord.fromJson(item as Map<String, dynamic>? ?? const {}),
    ];
  }

  Future<List<OwnerOrderRecord>> _loadMockOrders() async {
    final raw = await rootBundle.loadString('assets/mock/owner_orders.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in decoded)
        OwnerOrderRecord.fromJson(item as Map<String, dynamic>? ?? const {}),
    ];
  }

  Future<List<OwnerStatusRecord>> fetchShipmentStatuses() async {
    try {
      final records = await ApiService.getData<List<OwnerStatusRecord>>(
        '/owner/orders',
        requiresAuth: true,
        parser: (data) {
          final list = data as List<dynamic>? ?? const [];
          final records = <OwnerStatusRecord>[];
          for (final item in list) {
            final json = item as Map<String, dynamic>? ?? const {};
            if (_hasShipment(json)) {
              records.add(OwnerStatusRecord.fromShipmentOrder(json));
            }
          }
          return records;
        },
      );
      if (records.isNotEmpty) return records;
    } catch (_) {
      // Development fallback: shipment list API does not exist yet.
    }
    return _loadMockStatuses('assets/mock/owner_shipments.json');
  }

  Future<List<OwnerStatusRecord>> fetchReturnStatuses() async {
    try {
      final records = await ApiService.getData<List<OwnerStatusRecord>>(
        '/owner/returns',
        requiresAuth: true,
        parser: (data) {
          final list = data as List<dynamic>? ?? const [];
          return [
            for (final item in list)
              OwnerStatusRecord.fromReturnJson(
                item as Map<String, dynamic>? ?? const {},
              ),
          ];
        },
      );
      if (records.isNotEmpty) return records;
    } catch (_) {
      // Development fallback: keep return status QA usable without DB seed.
    }

    final raw = await rootBundle.loadString('assets/mock/owner_returns.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in decoded)
        OwnerStatusRecord.fromReturnJson(
          item as Map<String, dynamic>? ?? const {},
        ),
    ];
  }

  Future<List<OwnerReturnRequestRecord>> fetchReturnRequests() async {
    try {
      final records = await ApiService.getData<List<OwnerReturnRequestRecord>>(
        '/owner/returns',
        requiresAuth: true,
        parser: (data) {
          final list = data as List<dynamic>? ?? const [];
          return [
            for (final item in list)
              OwnerReturnRequestRecord.fromJson(
                item as Map<String, dynamic>? ?? const {},
              ),
          ].where((item) => item.status == '접수').toList();
        },
      );
      if (records.isNotEmpty) return records;
    } catch (_) {
      // Development fallback: keep return decision flow usable without DB seed.
    }

    final raw = await rootBundle.loadString('assets/mock/owner_returns.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in decoded)
        OwnerReturnRequestRecord.fromJson(
          item as Map<String, dynamic>? ?? const {},
          isFallback: true,
        ),
    ].where((item) => item.status == '접수').toList();
  }

  Future<bool> decideReturn({
    required OwnerReturnRequestRecord request,
    required String decision,
    required int approvedAmount,
    String? decisionReason,
  }) async {
    if (request.isFallback) return false;
    try {
      await ApiService.patchData<Map<String, dynamic>>(
        '/owner/returns/${request.id}/decision',
        requiresAuth: true,
        body: {
          'decision': decision,
          'approved_amount': approvedAmount,
          'decision_reason': decisionReason,
        },
        parser: (data) => data as Map<String, dynamic>? ?? const {},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<OwnerStatusRecord>> _loadMockStatuses(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in decoded)
        OwnerStatusRecord.fromJson(item as Map<String, dynamic>? ?? const {}),
    ];
  }

  bool _hasShipment(Map<String, dynamic> item) {
    return item['tracking_no'] != null || item['shipment_status'] != null;
  }
}

class OwnerProcurementDecisionItem {
  const OwnerProcurementDecisionItem({
    required this.procurementItemId,
    required this.approvedPackageCount,
    required this.approvedKg,
    this.ownerMemo,
  });

  final int procurementItemId;
  final int approvedPackageCount;
  final double approvedKg;
  final String? ownerMemo;
}
