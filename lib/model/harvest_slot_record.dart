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
    );
  }

  String get period =>
      '${_shortDate(predictedHarvestStart)}-${_shortDate(predictedHarvestEnd)}';
  String get expectedYield => '${estimatedYieldKg.round()}kg';
  String get reservation =>
      '${suggestedReservableMinKg.round()}-${suggestedReservableMaxKg.round()}kg';
  String get price => '${_money(recommendedPrice)}/kg';
  String get confidenceLabel => '${(confidence * 100).round()}%';
}

class HarvestSlotRecord {
  const HarvestSlotRecord({
    required this.slotId,
    required this.productName,
    required this.slotStatus,
  });

  final int slotId;
  final String productName;
  final String slotStatus;

  factory HarvestSlotRecord.fromJson(Map<String, dynamic> json) {
    return HarvestSlotRecord(
      slotId: _asInt(json['slot_id']),
      productName: json['product_name']?.toString() ?? '',
      slotStatus: json['slot_status']?.toString() ?? '',
    );
  }
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

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
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
