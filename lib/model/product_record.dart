import 'package:flutter/material.dart';

class ProductRecord {
  static const appleVarieties = ['양광', '부사'];
  static const packageUnitKgOptions = [1.0, 3.0, 5.0, 7.5, 10.0];

  final int? id;
  final int? farmId;
  final String name;
  final String packageUnit;
  final int price;
  final int stockKg;
  final String status;
  final Color color;
  final String fruitType;
  final String variety;
  final String? description;
  final String? imageUrl;

  const ProductRecord(
    this.name,
    this.packageUnit,
    this.price,
    this.stockKg,
    this.status,
    this.color, {
    this.id,
    this.farmId,
    this.fruitType = '사과',
    this.variety = '',
    this.description,
    this.imageUrl,
  });

  factory ProductRecord.fromJson(Map<String, dynamic> json) {
    final status = statusLabel(json['product_status']?.toString() ?? '');
    final packageUnitKg = _asDouble(json['package_unit_kg']);
    return ProductRecord(
      json['product_name']?.toString() ?? '',
      '${_formatKg(packageUnitKg)}kg 박스',
      _asInt(json['base_price']),
      _asInt(json['open_slot_count']),
      status,
      statusColor(status),
      id: _asIntOrNull(json['product_id']),
      farmId: _asIntOrNull(json['farm_id']),
      fruitType: json['fruit_type']?.toString() ?? '사과',
      variety: json['variety']?.toString() ?? '',
      description: json['product_description']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }

  ProductRecord copyWith({
    int? id,
    int? farmId,
    String? name,
    String? packageUnit,
    int? price,
    int? stockKg,
    String? status,
    Color? color,
    String? fruitType,
    String? variety,
    String? description,
    String? imageUrl,
  }) {
    final nextStatus = status ?? this.status;
    return ProductRecord(
      name ?? this.name,
      packageUnit ?? this.packageUnit,
      price ?? this.price,
      stockKg ?? this.stockKg,
      nextStatus,
      color ?? statusColor(nextStatus),
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      fruitType: fruitType ?? this.fruitType,
      variety: variety ?? this.variety,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  String get backendStatus => backendStatusFromLabel(status);

  double get packageUnitKg {
    final value = packageUnit.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(value) ?? 0;
  }

  String get priceLabel {
    final text = price.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }
    return '$buffer원';
  }

  static String statusLabel(String status) {
    return switch (status) {
      'ACTIVE' => '판매 중',
      'SOLD_OUT' => '준비 중',
      'HIDDEN' => '판매 중지',
      'INACTIVE' => '판매 중지',
      _ => status.isEmpty ? '준비 중' : status,
    };
  }

  static String backendStatusFromLabel(String status) {
    return switch (status) {
      '판매 중' => 'ACTIVE',
      '준비 중' => 'SOLD_OUT',
      '판매 중지' => 'HIDDEN',
      _ => status,
    };
  }

  static String productNameFromVariety(String variety) {
    return '$variety 사과';
  }

  static String varietyFromProductName(String productName) {
    for (final variety in appleVarieties) {
      if (productName.contains(variety)) {
        return variety;
      }
    }
    return appleVarieties.first;
  }

  static String packageLabel(double packageUnitKg) {
    return '${_formatKg(packageUnitKg)}kg 박스';
  }

  static Color statusColor(String status) {
    return switch (status) {
      '판매 중' => const Color(0xffDFF4E8),
      '준비 중' => const Color(0xffFFF1C7),
      _ => const Color(0xffFFE1DD),
    };
  }
}

class OwnerFarmRecord {
  const OwnerFarmRecord({
    required this.farmId,
    required this.farmName,
    required this.farmRegion,
    required this.farmAddress,
    this.farmImageUrl,
    this.farmDescription,
    this.deliveryPolicy,
    this.returnPolicy,
  });

  final int farmId;
  final String farmName;
  final String farmRegion;
  final String farmAddress;
  final String? farmImageUrl;
  final String? farmDescription;
  final String? deliveryPolicy;
  final String? returnPolicy;

  factory OwnerFarmRecord.fromJson(Map<String, dynamic> json) {
    return OwnerFarmRecord(
      farmId: _asInt(json['farm_id']),
      farmName: json['farm_name']?.toString() ?? '',
      farmRegion: json['farm_region']?.toString() ?? '',
      farmAddress: json['farm_address']?.toString() ?? '',
      farmImageUrl: json['farm_image_url']?.toString(),
      farmDescription: json['farm_description']?.toString(),
      deliveryPolicy: json['delivery_policy']?.toString(),
      returnPolicy: json['return_policy']?.toString(),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatKg(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}
