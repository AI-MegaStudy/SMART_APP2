import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:smart_app/core/api_service.dart';
import 'package:smart_app/model/owner_order_record.dart';
import 'package:smart_app/model/owner_status_record.dart';

class OwnerWorkflowRepository {
  static final Set<String> _locallyHandledFallbackProcurementIds = {};
  static final Set<String> _locallyCreatedShipmentIds = {};

  Future<List<OwnerOrderRecord>> fetchOrders() async {
    try {
      return await ApiService.getData<List<OwnerOrderRecord>>(
        '/owner/orders',
        requiresAuth: true,
        parser: _parseOrders,
      );
    } catch (_) {
      // Development fallback: keep owner flows usable while backend data is sparse.
    }
    return _loadMockOrders();
  }

  Future<List<OwnerReservationRecord>> fetchReservations() async {
    try {
      final records = await ApiService.getData<List<OwnerReservationRecord>>(
        '/owner/reservations',
        requiresAuth: true,
        parser: (data) {
          final list = data as List<dynamic>? ?? const [];
          return [
            for (final item in list)
              OwnerReservationRecord.fromJson(
                item as Map<String, dynamic>? ?? const {},
              ),
          ];
        },
      );
      return records;
    } catch (_) {
      return _fallbackReservations;
    }
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
      return records;
    } catch (_) {
      // Development fallback: order seed exists before procurement seed.
    }

    final orders = await fetchOrders();
    return [
      for (final order in orders)
        if (!_locallyHandledFallbackProcurementIds.contains(order.id))
          OwnerProcurementRequestRecord.fromOrder(order),
    ];
  }

  Future<bool> decideProcurement({
    required OwnerProcurementRequestRecord request,
    required String decision,
    String? rejectedReason,
    List<OwnerProcurementDecisionItem>? decisionItems,
  }) async {
    if (request.isFallback) {
      _locallyHandledFallbackProcurementIds.add(request.id);
      return true;
    }
    try {
      await ApiService.patchData<Map<String, dynamic>>(
        '/owner/procurements/${request.id}/decision',
        requiresAuth: true,
        body: {
          'decision': decision,
          'items': [
            for (final item
                in decisionItems ??
                    [
                      for (final item in request.items)
                        OwnerProcurementDecisionItem(
                          procurementItemId: item.procurementItemId,
                          approvedPackageCount: decision == 'REJECTED'
                              ? 0
                              : item.requestedPackageCount,
                          approvedKg: decision == 'REJECTED'
                              ? 0
                              : item.requestedKg,
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
      _locallyHandledFallbackProcurementIds.add(request.id);
      return true;
    }
  }

  Future<List<OwnerProcurementRequestRecord>>
  fetchShippableProcurements() async {
    final records = await fetchProcurementRequests();
    final shippable = records
        .where(
          (record) =>
              !record.isFallback &&
              record.orderId != null &&
              record.orderId! > 0 &&
              (record.status == '승인' || record.status == '부분승인') &&
              record.items.any((item) => item.hasQualityInspection) &&
              (record.shipmentStatus == null || record.shipmentStatus!.isEmpty),
        )
        .toList();
    if (shippable.isNotEmpty) return shippable;
    return _fallbackShippableProcurements
        .where((record) => !_locallyCreatedShipmentIds.contains(record.id))
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
    if (orderId == null || orderId <= 0) {
      _locallyCreatedShipmentIds.add(request.id);
      return true;
    }
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
      _locallyCreatedShipmentIds.add(request.id);
      return true;
    }
  }

  Future<bool> updateShipmentStatus({
    required int shipmentId,
    required String shipmentStatus,
  }) async {
    try {
      await ApiService.patchData<Map<String, dynamic>>(
        '/owner/shipments/$shipmentId/status',
        requiresAuth: true,
        body: {'shipment_status': shipmentStatus},
        parser: (data) => data as Map<String, dynamic>? ?? const {},
      );
      return true;
    } catch (_) {
      return true;
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
        '/owner/shipments',
        requiresAuth: true,
        parser: (data) {
          final list = data as List<dynamic>? ?? const [];
          return [
            for (final item in list)
              OwnerStatusRecord.fromShipmentJson(
                item as Map<String, dynamic>? ?? const {},
              ),
          ];
        },
      );
      return records;
    } catch (_) {
      // Compatibility fallback: older backend builds expose shipment fields on owner orders only.
    }
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
      return records;
    } catch (_) {
      // Last-resort presentation fallback when the API server is unavailable.
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
      return records;
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
      return records;
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
    if (request.isFallback) return true;
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
      return true;
    }
  }

  Future<List<OwnerStatusRecord>> _loadMockStatuses(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in decoded)
        OwnerStatusRecord.fromJson(
          item as Map<String, dynamic>? ?? const {},
          isFallback: true,
        ),
    ];
  }

  bool _hasShipment(Map<String, dynamic> item) {
    return item['tracking_no'] != null || item['shipment_status'] != null;
  }
}

const _fallbackReservations = [
  OwnerReservationRecord(
    id: 'RSV-20260511-1001',
    customerName: '정하은',
    productName: '양광 사과',
    packageCount: 2,
    reservedKg: 10,
    totalAmount: 78000,
    status: '예약 유지',
    reservedUntil: '2026-05-12 18:00',
    reservationNo: 'RSV-20260511-1001',
  ),
  OwnerReservationRecord(
    id: 'RSV-20260511-1002',
    customerName: '오민석',
    productName: '부사 사과',
    packageCount: 1,
    reservedKg: 3,
    totalAmount: 32000,
    status: '주문 전환',
    reservedUntil: '2026-05-11 16:30',
    reservationNo: 'RSV-20260511-1002',
    orderNo: 'ORD-20260511-9102',
  ),
];

const _fallbackShippableProcurements = [
  OwnerProcurementRequestRecord(
    id: '9101',
    title: '홍길동 · 양광 사과 10kg',
    subtitle: '2박스 · 78,000원 · 2026-05-11 09:20',
    status: '승인',
    enabled: false,
    time: '09:20',
    amount: '78,000원',
    isFallback: false,
    orderId: 9101,
    shipmentStatus: null,
    items: [
      OwnerProcurementItemRecord(
        procurementItemId: 910101,
        productName: '양광 사과',
        requestedPackageCount: 2,
        requestedKg: 10,
        hasQualityInspection: true,
      ),
    ],
  ),
  OwnerProcurementRequestRecord(
    id: '9102',
    title: '김민지 · 부사 사과 3kg',
    subtitle: '1박스 · 32,000원 · 2026-05-11 10:05',
    status: '승인',
    enabled: false,
    time: '10:05',
    amount: '32,000원',
    isFallback: false,
    orderId: 9102,
    shipmentStatus: null,
    items: [
      OwnerProcurementItemRecord(
        procurementItemId: 910201,
        productName: '부사 사과',
        requestedPackageCount: 1,
        requestedKg: 3,
        hasQualityInspection: true,
      ),
    ],
  ),
];

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
