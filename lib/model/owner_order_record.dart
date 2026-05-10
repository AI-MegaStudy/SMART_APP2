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

class OwnerReservationRecord {
  const OwnerReservationRecord({
    required this.id,
    required this.customerName,
    required this.productName,
    required this.packageCount,
    required this.reservedKg,
    required this.totalAmount,
    required this.status,
    required this.reservedUntil,
    this.reservationNo,
    this.orderNo,
  });

  final String id;
  final String customerName;
  final String productName;
  final int packageCount;
  final int reservedKg;
  final int totalAmount;
  final String status;
  final String reservedUntil;
  final String? reservationNo;
  final String? orderNo;

  factory OwnerReservationRecord.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    final firstItem = items.isEmpty
        ? const <String, dynamic>{}
        : items.first as Map<String, dynamic>? ?? const {};
    return OwnerReservationRecord(
      id: (json['reservation_id'] ?? json['reservation_no'] ?? '').toString(),
      customerName: json['customer_name']?.toString() ?? '고객',
      productName: firstItem['product_name']?.toString() ?? '상품',
      packageCount: _asInt(firstItem['package_count'], fallback: 1),
      reservedKg: _asInt(json['total_reserved_kg']),
      totalAmount: _asInt(json['total_amount']),
      status: _reservationStatusLabel(
        json['reservation_status']?.toString() ?? '',
        json['order_status']?.toString(),
      ),
      reservedUntil: _formatOrderedAt(json['reserved_until']),
      reservationNo: json['reservation_no']?.toString(),
      orderNo: json['order_no']?.toString(),
    );
  }

  String get title => '$customerName · $productName ${reservedKg}kg';

  String get subtitle {
    final progress = status == '주문 전환'
        ? '주문 전환 완료'
        : status == '예약 유지'
        ? '예약 마감 $reservedUntil'
        : status;
    return '$packageCount박스 · ${_money(totalAmount)} · $progress';
  }

  Color get color => switch (status) {
    '주문 전환' => AppColors.blue,
    '예약 만료' || '예약 취소' => const Color(0xffFFE1DD),
    _ => AppColors.mint,
  };
}

class OwnerProcurementRequestRecord {
  const OwnerProcurementRequestRecord({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.enabled,
    required this.time,
    required this.amount,
    required this.isFallback,
    required this.items,
    this.orderId,
    this.shipmentStatus,
  });

  final String id;
  final String title;
  final String subtitle;
  final String status;
  final bool enabled;
  final String time;
  final String amount;
  final bool isFallback;
  final List<OwnerProcurementItemRecord> items;
  final int? orderId;
  final String? shipmentStatus;

  Color get color => switch (status) {
    '승인' => AppColors.mint,
    '부분승인' => AppColors.blue,
    '거절' => const Color(0xffFFE1DD),
    _ => AppColors.yellow,
  };

  factory OwnerProcurementRequestRecord.fromProcurementJson(
    Map<String, dynamic> json,
  ) {
    final items = json['items'] as List<dynamic>? ?? const [];
    final parsedItems = [
      for (final item in items)
        OwnerProcurementItemRecord.fromJson(
          item as Map<String, dynamic>? ?? const {},
        ),
    ];
    final first = parsedItems.isEmpty ? null : parsedItems.first;
    final customer = json['customer_name']?.toString() ?? '고객';
    final product = first?.productName ?? '상품';
    final packages = first?.requestedPackageCount ?? 1;
    final kg = first?.requestedKg.round() ?? 0;
    final totalAmount = _asInt(json['total_amount']);
    final status = _procurementStatusLabel(
      json['procurement_status']?.toString() ?? '',
    );
    final requestedAt = _formatOrderedAt(json['requested_at']);
    return OwnerProcurementRequestRecord(
      id: (json['procurement_id'] ?? '').toString(),
      title: '$customer · $product ${kg}kg',
      subtitle: '$packages박스 · ${_money(totalAmount)} · $requestedAt',
      status: status,
      enabled: status == '승인 대기',
      time: requestedAt.split(' ').last,
      amount: _money(totalAmount),
      isFallback: false,
      items: parsedItems,
      orderId: _asInt(json['order_id']),
      shipmentStatus: json['shipment_status']?.toString(),
    );
  }

  factory OwnerProcurementRequestRecord.fromOrder(OwnerOrderRecord order) {
    return OwnerProcurementRequestRecord(
      id: order.id,
      title: order.title,
      subtitle: order.subtitle,
      status: order.status,
      enabled: order.status == '결제 완료',
      time: order.time,
      amount: order.amount,
      isFallback: true,
      items: [
        OwnerProcurementItemRecord(
          procurementItemId: int.tryParse(order.id) ?? 0,
          productName: order.productName,
          requestedPackageCount: order.packageCount,
          requestedKg: order.orderedKg.toDouble(),
          hasQualityInspection: false,
        ),
      ],
      orderId: int.tryParse(order.id),
      shipmentStatus: null,
    );
  }
}

class OwnerProcurementItemRecord {
  const OwnerProcurementItemRecord({
    required this.procurementItemId,
    required this.productName,
    required this.requestedPackageCount,
    required this.requestedKg,
    required this.hasQualityInspection,
  });

  final int procurementItemId;
  final String productName;
  final int requestedPackageCount;
  final double requestedKg;
  final bool hasQualityInspection;

  factory OwnerProcurementItemRecord.fromJson(Map<String, dynamic> json) {
    return OwnerProcurementItemRecord(
      procurementItemId: _asInt(json['procurement_item_id']),
      productName: json['product_name']?.toString() ?? '상품',
      requestedPackageCount: _asInt(
        json['requested_package_count'],
        fallback: 1,
      ),
      requestedKg: _asDouble(json['requested_kg']),
      hasQualityInspection: json['has_quality_inspection'] == true,
    );
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

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _procurementStatusLabel(String status) {
  return switch (status) {
    'REQUESTED' => '승인 대기',
    'APPROVED' => '승인',
    'PARTIAL_APPROVED' => '부분승인',
    'REJECTED' => '거절',
    _ => status.isEmpty ? '승인 대기' : status,
  };
}

String _reservationStatusLabel(String status, String? orderStatus) {
  if ((orderStatus ?? '').isNotEmpty || status == 'ORDERED') {
    return '주문 전환';
  }
  return switch (status) {
    'RESERVED' => '예약 유지',
    'EXPIRED' => '예약 만료',
    'CANCELED' => '예약 취소',
    _ => status.isEmpty ? '예약 유지' : status,
  };
}
