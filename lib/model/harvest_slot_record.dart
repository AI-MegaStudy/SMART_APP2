import 'package:smart_app/model/product_record.dart';

class HarvestPredictionRecord {
  const HarvestPredictionRecord({
    required this.predictionId,
    required this.farmId,
    required this.productId,
    required this.predictedHarvestStart,
    required this.predictedHarvestEnd,
    required this.estimatedYieldKg,
    required this.suggestedReservableMinKg,
    required this.suggestedReservableMaxKg,
    required this.recommendedPrice,
    required this.confidence,
    required this.warningMessage,
    this.unitYieldKg10a,
    this.safetyFactor,
    this.modelVersion,
  });

  final int predictionId;
  final int farmId;
  final int productId;
  final String predictedHarvestStart;
  final String predictedHarvestEnd;
  final double estimatedYieldKg;
  final double suggestedReservableMinKg;
  final double suggestedReservableMaxKg;
  final int recommendedPrice;
  final double confidence;
  final String warningMessage;
  final double? unitYieldKg10a;
  final double? safetyFactor;
  final String? modelVersion;

  factory HarvestPredictionRecord.fromJson(Map<String, dynamic> json) {
    return HarvestPredictionRecord(
      predictionId: _asInt(json['prediction_id']),
      farmId: _asInt(json['farm_id']),
      productId: _asInt(json['product_id']),
      predictedHarvestStart: json['predicted_harvest_start']?.toString() ?? '',
      predictedHarvestEnd: json['predicted_harvest_end']?.toString() ?? '',
      estimatedYieldKg: _asDouble(json['estimated_yield_kg']),
      suggestedReservableMinKg: _asDouble(json['suggested_reservable_min_kg']),
      suggestedReservableMaxKg: _asDouble(json['suggested_reservable_max_kg']),
      recommendedPrice: _asInt(json['recommended_price']),
      confidence: _asDouble(json['confidence']),
      warningMessage: json['warning_message']?.toString() ?? '',
      unitYieldKg10a: _asDoubleOrNull(json['unit_yield_kg_10a']),
      safetyFactor: _asDoubleOrNull(json['safety_factor']),
      modelVersion: json['model_version']?.toString(),
    );
  }

  String get period =>
      '${_shortDate(predictedHarvestStart)}-${_shortDate(predictedHarvestEnd)}';
  String get expectedYield => '${estimatedYieldKg.round()}kg';
  String get reservation =>
      '${suggestedReservableMinKg.round()}-${suggestedReservableMaxKg.round()}kg';
  String get price => '${_money(recommendedPrice)}/kg';
  String get confidenceLabel => '${(confidence * 100).round()}%';
  String get standardAreaYieldValue =>
      unitYieldKg10a == null ? '' : '${unitYieldKg10a!.round()}kg';
  String get standardAreaYieldLabel =>
      unitYieldKg10a == null ? '' : '1,000㎡ 기준 수확량';
  String get standardAreaYieldBadge =>
      unitYieldKg10a == null ? '' : '${unitYieldKg10a!.round()}kg/1,000㎡';
  List<double> get trendValues {
    final base = estimatedYieldKg <= 0 ? 1.0 : estimatedYieldKg;
    final confidenceSpread = (1 - confidence.clamp(0.0, 1.0)) * 0.16;
    return [
      base * (0.78 - confidenceSpread),
      base * (0.88 - confidenceSpread / 2),
      base * 0.96,
      base,
      base * (0.94 + confidenceSpread / 2),
    ];
  }

  List<String> get trendLabels {
    final start = DateTime.tryParse(predictedHarvestStart);
    if (start == null) {
      return const ['초기', '생육', '비대', '수확', '정리'];
    }
    return [
      for (var index = 0; index < 5; index++)
        _shortDate(start.add(Duration(days: index)).toIso8601String()),
    ];
  }
}

class HarvestSlotRecord {
  const HarvestSlotRecord({
    required this.slotId,
    required this.productName,
    required this.slotStatus,
    required this.confirmedHarvestStart,
    required this.confirmedHarvestEnd,
    required this.confirmedReservableKg,
    required this.reservedKg,
    required this.soldKg,
    required this.availableKg,
    required this.confirmedPrice,
    required this.customerNotice,
    this.farmId,
    this.productId,
    this.farmName,
    this.imageUrl,
    this.packageUnitKg,
    this.predictionId,
  });

  final int slotId;
  final String productName;
  final String slotStatus;
  final int? farmId;
  final int? productId;
  final String? farmName;
  final String? imageUrl;
  final double? packageUnitKg;
  final int? predictionId;
  final String confirmedHarvestStart;
  final String confirmedHarvestEnd;
  final double confirmedReservableKg;
  final double reservedKg;
  final double soldKg;
  final double availableKg;
  final int confirmedPrice;
  final String customerNotice;

  factory HarvestSlotRecord.fromJson(Map<String, dynamic> json) {
    return HarvestSlotRecord(
      slotId: _asInt(json['slot_id']),
      productName: json['product_name']?.toString() ?? '',
      slotStatus: json['slot_status']?.toString() ?? '',
      farmId: _asIntOrNull(json['farm_id']),
      productId: _asIntOrNull(json['product_id']),
      farmName: json['farm_name']?.toString(),
      imageUrl: json['image_url']?.toString(),
      packageUnitKg: _asDoubleOrNull(json['package_unit_kg']),
      predictionId: _asIntOrNull(json['prediction_id']),
      confirmedHarvestStart: json['confirmed_harvest_start']?.toString() ?? '',
      confirmedHarvestEnd: json['confirmed_harvest_end']?.toString() ?? '',
      confirmedReservableKg: _asDouble(json['confirmed_reservable_kg']),
      reservedKg: _asDouble(json['reserved_kg']),
      soldKg: _asDouble(json['sold_kg']),
      availableKg: _asDouble(json['available_kg']),
      confirmedPrice: _asInt(json['confirmed_price']),
      customerNotice: json['customer_notice']?.toString() ?? '',
    );
  }

  HarvestSlotRecord copyWith({
    String? confirmedHarvestStart,
    String? confirmedHarvestEnd,
    double? confirmedReservableKg,
    int? confirmedPrice,
    String? customerNotice,
    String? slotStatus,
  }) {
    return HarvestSlotRecord(
      slotId: slotId,
      productName: productName,
      slotStatus: slotStatus ?? this.slotStatus,
      confirmedHarvestStart:
          confirmedHarvestStart ?? this.confirmedHarvestStart,
      confirmedHarvestEnd: confirmedHarvestEnd ?? this.confirmedHarvestEnd,
      confirmedReservableKg:
          confirmedReservableKg ?? this.confirmedReservableKg,
      reservedKg: reservedKg,
      soldKg: soldKg,
      availableKg: availableKg,
      confirmedPrice: confirmedPrice ?? this.confirmedPrice,
      customerNotice: customerNotice ?? this.customerNotice,
      farmId: farmId,
      productId: productId,
      farmName: farmName,
      imageUrl: imageUrl,
      packageUnitKg: packageUnitKg,
      predictionId: predictionId,
    );
  }

  String get statusLabel => switch (slotStatus) {
    'OPEN' => '예약 중',
    'CLOSED' => '마감',
    'DRAFT' => '준비 중',
    _ => slotStatus,
  };

  String get period =>
      '${_shortDate(confirmedHarvestStart)}-${_shortDate(confirmedHarvestEnd)}';

  String get reservableLabel => '${confirmedReservableKg.round()}kg';
  String get availableLabel => '${availableKg.round()}kg 남음';
  String get priceLabel => '${_money(confirmedPrice)}/kg';
}

class HarvestProductOption {
  const HarvestProductOption({required this.product, required this.farm});

  final ProductRecord product;
  final OwnerFarmRecord farm;
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

double? _asDoubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String _shortDate(String value) {
  if (value.length >= 10) {
    return value.substring(5, 10).replaceFirst('-', '.');
  }
  return value;
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
