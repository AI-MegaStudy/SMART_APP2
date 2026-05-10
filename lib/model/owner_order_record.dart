import 'package:flutter/material.dart';
import 'package:smart_app/util/app_colors.dart';

class OwnerOrderRecord {
  const OwnerOrderRecord({
    required this.id,
    required this.customerName,
    required this.productName,
    required this.packageCount,
    required this.orderedKg,
    required this.totalAmount,
    required this.status,
    required this.orderedAt,
    this.orderNo,
  });

  final String id;
  final String customerName;
  final String productName;
  final int packageCount;
  final int orderedKg;
  final int totalAmount;
  final String status;
  final String orderedAt;
  final String? orderNo;

  factory OwnerOrderRecord.fromJson(Map<String, dynamic> json) {
    final items = json['order_items'] as List<dynamic>? ?? const [];
    final firstItem = items.isEmpty
        ? const <String, dynamic>{}
        : items.first as Map<String, dynamic>? ?? const {};
    final paymentStatus = json['payment_status']?.toString() ?? '';
    final orderStatus = json['order_status']?.toString() ?? '';
    return OwnerOrderRecord(
      id: (json['order_id'] ?? json['order_no'] ?? '').toString(),
      customerName: json['customer_name']?.toString() ?? '고객',
      productName: firstItem['product_name']?.toString() ?? '상품',
      packageCount: _asInt(firstItem['package_count'], fallback: 1),
      orderedKg: _asInt(firstItem['ordered_kg'], fallback: 0),
      totalAmount: _asInt(json['total_amount']),
      status: _statusLabel(
        orderStatus: orderStatus,
        paymentStatus: paymentStatus,
      ),
      orderedAt: _formatOrderedAt(json['ordered_at']),
      orderNo: json['order_no']?.toString(),
    );
  }

  String get title => '$customerName · $productName ${orderedKg}kg';

  String get subtitle =>
      '$packageCount박스 · ${_money(totalAmount)} · $orderedAt';

  String get time {
    final parts = orderedAt.split(' ');
    return parts.length > 1 ? parts.last : orderedAt;
  }

  String get amount => _money(totalAmount);

  Color get color => switch (status) {
    '결제 완료' => AppColors.blue,
    '주문 완료' => AppColors.yellow,
    _ => AppColors.mint,
  };

  static String _statusLabel({
    required String orderStatus,
    required String paymentStatus,
  }) {
    if (paymentStatus == 'APPROVED' ||
        orderStatus == 'PAID' ||
        orderStatus == 'PROCUREMENT_REQUESTED') {
      return '결제 완료';
    }
    return '주문 완료';
  }
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _formatOrderedAt(Object? value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return '';
  final normalized = raw.replaceFirst('T', ' ');
  return normalized.length >= 16 ? normalized.substring(0, 16) : normalized;
}

String _money(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(text[i]);
  }
  return '$buffer원';
}
