import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:smart_app/core/api_service.dart';
import 'package:smart_app/model/owner_order_record.dart';

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
}
