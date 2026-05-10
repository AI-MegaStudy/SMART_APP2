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
