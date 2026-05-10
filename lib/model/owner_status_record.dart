import 'package:flutter/material.dart';
import 'package:smart_app/util/app_colors.dart';

class OwnerStatusRecord {
  const OwnerStatusRecord({
    required this.title,
    required this.subtitle,
    required this.status,
    this.shipmentId,
    this.rawStatus,
    this.isFallback = false,
  });

  final String title;
  final String subtitle;
  final String status;
  final int? shipmentId;
  final String? rawStatus;
  final bool isFallback;

  factory OwnerStatusRecord.fromJson(
    Map<String, dynamic> json, {
    bool isFallback = false,
  }) {
    return OwnerStatusRecord(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      shipmentId: _nullableInt(json['shipment_id']),
      rawStatus: json['shipment_status']?.toString(),
      isFallback: isFallback,
    );
  }

  factory OwnerStatusRecord.fromShipmentOrder(Map<String, dynamic> json) {
    final items = json['order_items'] as List<dynamic>? ?? const [];
    final firstItem = items.isEmpty
        ? const <String, dynamic>{}
        : items.first as Map<String, dynamic>? ?? const {};
    final product = firstItem['product_name']?.toString() ?? '상품';
    final customer = json['customer_name']?.toString() ?? '고객';
    final kg = _asInt(firstItem['ordered_kg']);
    final boxes = _asInt(firstItem['package_count'], fallback: 1);
    final carrier = json['carrier_name']?.toString().isNotEmpty == true
        ? json['carrier_name'].toString()
        : '택배사 미정';
    final tracking = json['tracking_no']?.toString().isNotEmpty == true
        ? json['tracking_no'].toString()
        : '송장 미등록';
    return OwnerStatusRecord(
      title: '$customer · $product ${kg}kg · $boxes박스',
      subtitle: '$carrier · $tracking',
      status: _shipmentStatusLabel(json['shipment_status']?.toString() ?? ''),
      shipmentId: _nullableInt(json['shipment_id']),
      rawStatus: json['shipment_status']?.toString(),
    );
  }

  factory OwnerStatusRecord.fromReturnJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    final firstItem = items.isEmpty
        ? const <String, dynamic>{}
        : items.first as Map<String, dynamic>? ?? const {};
    final product =
        json['product_name']?.toString() ??
        firstItem['product_name']?.toString() ??
        '상품';
    final kg = _asInt(json['ordered_kg'] ?? firstItem['ordered_kg']);
    final boxes = _asInt(
      json['package_count'] ?? firstItem['package_count'],
      fallback: 1,
    );
    final customer = json['customer_name']?.toString() ?? '고객';
    final status = _returnStatusLabel(json['return_status']?.toString() ?? '');
    final detail = status == '승인'
        ? _money(_asInt(json['approved_amount'] ?? json['requested_amount']))
        : json['decision_reason']?.toString().isNotEmpty == true
        ? json['decision_reason'].toString()
        : json['reason_code']?.toString() ?? '접수';
    return OwnerStatusRecord(
      title: _formatDateTime(json['requested_at']),
      subtitle: '$customer · $product ${kg}kg · $boxes박스 · $detail',
      status: status,
    );
  }

  Color get color => switch (status) {
    '배송 완료' => AppColors.blue,
    '배송 중' || '승인' => AppColors.mint,
    '거절' => AppColors.yellow,
    _ => AppColors.yellow,
  };
}

class OwnerReturnRequestRecord {
  const OwnerReturnRequestRecord({
    required this.id,
    required this.customerName,
    required this.reason,
    required this.productName,
    required this.requestedAt,
    required this.amount,
    required this.detailReason,
    required this.status,
    required this.photoCount,
    required this.isFallback,
  });

  final int id;
  final String customerName;
  final String reason;
  final String productName;
  final String requestedAt;
  final String amount;
  final String detailReason;
  final String status;
  final int photoCount;
  final bool isFallback;

  factory OwnerReturnRequestRecord.fromJson(
    Map<String, dynamic> json, {
    bool isFallback = false,
  }) {
    final items = json['items'] as List<dynamic>? ?? const [];
    final firstItem = items.isEmpty
        ? const <String, dynamic>{}
        : items.first as Map<String, dynamic>? ?? const {};
    final product =
        json['product_name']?.toString() ??
        firstItem['product_name']?.toString() ??
        '상품';
    final kg = _asInt(json['ordered_kg'] ?? firstItem['ordered_kg']);
    final boxes = _asInt(
      json['package_count'] ?? firstItem['package_count'],
      fallback: 1,
    );
    return OwnerReturnRequestRecord(
      id: _asInt(json['return_request_id']),
      customerName: json['customer_name']?.toString() ?? '고객',
      reason: json['reason_code']?.toString() ?? '반품 요청',
      productName: '$product ${kg}kg · $boxes박스',
      requestedAt: _formatDateTime(json['requested_at']),
      amount: _asInt(json['requested_amount']).toString(),
      detailReason: json['reason_detail']?.toString() ?? '',
      status: _returnStatusLabel(json['return_status']?.toString() ?? ''),
      photoCount: json['evidence_image_url']?.toString().isNotEmpty == true
          ? 1
          : 0,
      isFallback: isFallback,
    );
  }

  String get key => '$id-$customerName-$requestedAt';
  String get title => '$customerName · $reason';
  String get subtitle => '$productName · $requestedAt';
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String _shipmentStatusLabel(String status) {
  return switch (status) {
    'SHIPPED' => '배송 중',
    'DELIVERED' => '배송 완료',
    '' => '배송 대기',
    _ => status,
  };
}

String _returnStatusLabel(String status) {
  return switch (status) {
    'APPROVED' || 'REFUNDED' => '승인',
    'REJECTED' => '거절',
    _ => '접수',
  };
}

String _formatDateTime(Object? value) {
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
