import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_app/model/harvest_slot_record.dart';
import 'package:smart_app/model/product_record.dart';
import 'package:smart_app/repositories/harvest_repository.dart';

void main() {
  test('HarvestRepository builds ML prediction request from backend guide', () {
    final repository = HarvestRepository();
    const option = HarvestProductOption(
      farm: OwnerFarmRecord(
        farmId: 1,
        farmName: '테스트 농장',
        farmRegion: '충북',
        farmAddress: '충북 청주',
      ),
      product: ProductRecord(
        '부사 사과',
        '5kg 박스',
        5000,
        12,
        '판매 중',
        Color(0xffDFF4E8),
        id: 1,
        farmId: 1,
        variety: '부사',
      ),
    );

    final request = repository.buildPredictionRequest(
      option,
      pastYieldKg: 3000,
      recentWeather: '평년 수준',
      cultivationStatus: '양호',
    );

    expect(request['farm_id'], 1);
    expect(request['product_id'], 1);
    expect(request['features'], {
      'past_yield_kg': 3000,
      'market_price': 5000,
      'variety': '부사',
      'mar_avg_temp': 8.5,
      'aug_sunshine': 210.0,
      'oct_rainfall': 65.0,
      'aug_humidity': 72.0,
    });
  });

  test('HarvestPredictionRecord maps backend ML response extras', () {
    final record = HarvestPredictionRecord.fromJson(const {
      'prediction_id': 1,
      'farm_id': 1,
      'product_id': 1,
      'unit_yield_kg_10a': 1509.54,
      'predicted_harvest_start': '2026-06-10',
      'predicted_harvest_end': '2026-06-15',
      'estimated_yield_kg': 3019.08,
      'suggested_reservable_min_kg': 1207.63,
      'suggested_reservable_max_kg': 2264.31,
      'recommended_price': 5000,
      'confidence': 0.78,
      'safety_factor': 0.75,
      'warning_message': '정상',
      'model_version': 'rf-apple-harvest-v1',
    });

    expect(record.unitYieldKg10a, 1509.54);
    expect(record.safetyFactor, 0.75);
    expect(record.modelVersion, 'rf-apple-harvest-v1');
    expect(record.expectedYield, '3019kg');
    expect(record.reservation, '1208-2264kg');
    expect(record.standardAreaYieldValue, '1510kg');
    expect(record.standardAreaYieldLabel, '1,000㎡ 기준 수확량');
  });
}
