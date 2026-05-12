import 'package:flutter/material.dart';
import 'package:smart_app/core/api_debug_log.dart';
import 'package:smart_app/core/api_service.dart';
import 'package:smart_app/model/harvest_slot_record.dart';
import 'package:smart_app/model/product_record.dart';
import 'package:smart_app/repositories/product_repository.dart';

class HarvestRepository {
  HarvestRepository({ProductRepository? productRepository})
    : productRepository = productRepository ?? ProductRepository();

  final ProductRepository productRepository;

  Future<List<HarvestProductOption>> fetchProductOptions() async {
    try {
      final farms = await productRepository.fetchOwnerFarms();
      final products = await productRepository.fetchOwnerProducts();
      final options = [
        for (final product in products)
          if (product.id != null &&
              product.farmId != null &&
              product.status != '판매 중지')
            HarvestProductOption(
              product: product,
              farm: farms.firstWhere(
                (farm) => farm.farmId == product.farmId,
                orElse: () => farms.isEmpty
                    ? OwnerFarmRecord(
                        farmId: product.farmId!,
                        farmName: '',
                        farmRegion: '',
                        farmAddress: '',
                      )
                    : farms.first,
              ),
            ),
      ];
      if (options.isNotEmpty) {
        ApiDebugLog.ok('harvest.products', 'options=${options.length}');
        return options;
      }
      ApiDebugLog.fallbackReason(
        'harvest.products',
        '상품/농장 API 호출은 성공했지만 선택 가능한 상품이 없어 fallback 상품을 사용합니다.',
      );
      return _fallbackProductOptions();
    } catch (error) {
      ApiDebugLog.fallback('harvest.products', error, message: '상품/농장 API 실패');
      return _fallbackProductOptions();
    }
  }

  Future<HarvestPredictionRecord> createPrediction(
    HarvestProductOption option, {
    required int pastYieldKg,
    required String recentWeather,
    required String cultivationStatus,
  }) async {
    try {
      final requestBody = buildPredictionRequest(
        option,
        pastYieldKg: pastYieldKg,
        recentWeather: recentWeather,
        cultivationStatus: cultivationStatus,
      );
      final autoWeatherBody = buildAutoWeatherPredictionRequest(
        option,
        pastYieldKg: pastYieldKg,
      );
      final record = await _createPredictionWithAutoWeather(
        autoWeatherBody,
        fallbackBody: requestBody,
      );
      ApiDebugLog.ok(
        'harvest.prediction',
        'request=$autoWeatherBody result='
            'id=${record.predictionId}, model=${record.modelVersion}, '
            'unitYield10a=${record.unitYieldKg10a}, '
            'estimated=${record.estimatedYieldKg}, '
            'reservable=${record.suggestedReservableMinKg}-${record.suggestedReservableMaxKg}, '
            'price=${record.recommendedPrice}, period=${record.predictedHarvestStart}-${record.predictedHarvestEnd}',
      );
      return record;
    } catch (error) {
      ApiDebugLog.fallback(
        'harvest.prediction',
        error,
        message:
            '수확 예측 API 실패. 앱 내부 계산값을 사용합니다. '
            'pastYield=$pastYieldKg, weather=$recentWeather, cultivation=$cultivationStatus',
      );
      final fallback = _fallbackPrediction(
        option,
        pastYieldKg: pastYieldKg,
        recentWeather: recentWeather,
        cultivationStatus: cultivationStatus,
      );
      ApiDebugLog.fallbackReason(
        'harvest.prediction',
        'fallback result=id=${fallback.predictionId}, '
            'estimated=${fallback.estimatedYieldKg}, '
            'reservable=${fallback.suggestedReservableMinKg}-${fallback.suggestedReservableMaxKg}, '
            'price=${fallback.recommendedPrice}, period=${fallback.predictedHarvestStart}-${fallback.predictedHarvestEnd}',
      );
      return fallback;
    }
  }

  Map<String, Object?> buildPredictionRequest(
    HarvestProductOption option, {
    required int pastYieldKg,
    required String recentWeather,
    required String cultivationStatus,
  }) {
    final climate = _climateFeatures(
      recentWeather: recentWeather,
      cultivationStatus: cultivationStatus,
    );
    return {
      'farm_id': option.farm.farmId,
      'product_id': option.product.id,
      'features': {
        'past_yield_kg': pastYieldKg,
        'market_price': option.product.price,
        'variety': option.product.variety.isEmpty
            ? ProductRecord.varietyFromProductName(option.product.name)
            : option.product.variety,
        'mar_avg_temp': climate.marAvgTemp,
        'aug_sunshine': climate.augSunshine,
        'oct_rainfall': climate.octRainfall,
        'aug_humidity': climate.augHumidity,
      },
    };
  }

  Map<String, Object?> buildAutoWeatherPredictionRequest(
    HarvestProductOption option, {
    required int pastYieldKg,
  }) {
    return {
      'farm_id': option.farm.farmId,
      'product_id': option.product.id,
      'target_year': DateTime.now().year,
      'stn_id': '136',
      'past_yield_kg': pastYieldKg,
      'market_price': option.product.price,
      'variety': option.product.variety.isEmpty
          ? ProductRecord.varietyFromProductName(option.product.name)
          : option.product.variety,
    };
  }

  Future<HarvestPredictionRecord> _createPredictionWithAutoWeather(
    Map<String, Object?> body, {
    required Map<String, Object?> fallbackBody,
  }) async {
    try {
      return await ApiService.postData<HarvestPredictionRecord>(
        '/owner/ml/predictions/auto-weather',
        requiresAuth: true,
        body: body,
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return HarvestPredictionRecord.fromJson(json);
        },
      );
    } catch (error) {
      ApiDebugLog.fallback(
        'harvest.weather',
        error,
        message: '날씨 API 기반 예측 실패. 화면 입력값 기준 예측으로 전환합니다.',
      );
      return await ApiService.postData<HarvestPredictionRecord>(
        '/owner/ml/predictions',
        requiresAuth: true,
        body: fallbackBody,
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return HarvestPredictionRecord.fromJson(json);
        },
      );
    }
  }

  _MlClimateFeatures _climateFeatures({
    required String recentWeather,
    required String cultivationStatus,
  }) {
    var features = switch (recentWeather) {
      '고온' => const _MlClimateFeatures(
        marAvgTemp: 10.2,
        augSunshine: 245,
        octRainfall: 52,
        augHumidity: 66,
      ),
      '저온' => const _MlClimateFeatures(
        marAvgTemp: 5.8,
        augSunshine: 184,
        octRainfall: 71,
        augHumidity: 74,
      ),
      '강수 많음' => const _MlClimateFeatures(
        marAvgTemp: 8.1,
        augSunshine: 158,
        octRainfall: 132,
        augHumidity: 86,
      ),
      _ => const _MlClimateFeatures(
        marAvgTemp: 8.5,
        augSunshine: 210,
        octRainfall: 65,
        augHumidity: 72,
      ),
    };

    if (cultivationStatus == '관수 필요') {
      features = features.copyWith(augHumidity: features.augHumidity - 6);
    } else if (cultivationStatus == '병해 확인') {
      features = features.copyWith(
        augSunshine: features.augSunshine - 18,
        augHumidity: features.augHumidity + 5,
      );
    }
    return features;
  }

  Future<HarvestSlotRecord> createOpenSlot({
    required HarvestProductOption option,
    required HarvestPredictionRecord prediction,
    required String confirmedHarvestStart,
    required String confirmedHarvestEnd,
    required int confirmedReservableKg,
    required int confirmedPrice,
    required String customerNotice,
  }) async {
    try {
      return await ApiService.postData<HarvestSlotRecord>(
        '/owner/harvest-slots',
        requiresAuth: true,
        body: {
          'farm_id': option.farm.farmId,
          'product_id': option.product.id,
          'prediction_id': prediction.predictionId,
          'confirmed_harvest_start': confirmedHarvestStart,
          'confirmed_harvest_end': confirmedHarvestEnd,
          'confirmed_reservable_kg': confirmedReservableKg,
          'confirmed_price': confirmedPrice,
          'customer_notice': customerNotice,
          'slot_status': 'OPEN',
        },
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return HarvestSlotRecord.fromJson(json);
        },
      );
    } catch (_) {
      return HarvestSlotRecord(
        slotId: 9901,
        productName: option.product.name,
        slotStatus: 'OPEN',
        confirmedHarvestStart: confirmedHarvestStart,
        confirmedHarvestEnd: confirmedHarvestEnd,
        confirmedReservableKg: confirmedReservableKg.toDouble(),
        reservedKg: 0,
        soldKg: 0,
        availableKg: confirmedReservableKg.toDouble(),
        confirmedPrice: confirmedPrice,
        customerNotice: customerNotice,
        farmId: option.farm.farmId,
        productId: option.product.id,
        farmName: option.farm.farmName,
        imageUrl: option.product.imageUrl,
        packageUnitKg: option.product.packageUnitKg,
        predictionId: prediction.predictionId,
      );
    }
  }

  Future<List<HarvestSlotRecord>> fetchOwnerSlots() async {
    try {
      final slots = await ApiService.getData<List<HarvestSlotRecord>>(
        '/owner/harvest-slots',
        requiresAuth: true,
        parser: (data) {
          final list = data as List<dynamic>? ?? const [];
          return [
            for (final item in list)
              HarvestSlotRecord.fromJson(
                item as Map<String, dynamic>? ?? const {},
              ),
          ];
        },
      );
      ApiDebugLog.ok('harvest.slots', 'count=${slots.length}');
      return slots;
    } catch (error) {
      ApiDebugLog.fallback('harvest.slots', error, message: '수확 슬롯 API 실패');
      return _fallbackSlots();
    }
  }

  Future<HarvestSlotRecord> updateSlotStatus({
    required int slotId,
    required String status,
  }) async {
    try {
      return await ApiService.patchData<HarvestSlotRecord>(
        '/owner/harvest-slots/$slotId/status',
        requiresAuth: true,
        body: {'slot_status': status},
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return HarvestSlotRecord.fromJson(json);
        },
      );
    } catch (_) {
      final fallback = _fallbackSlots().firstWhere(
        (slot) => slot.slotId == slotId,
        orElse: () => _fallbackSlots().first,
      );
      return fallback.copyWith(slotStatus: status);
    }
  }

  Future<HarvestSlotRecord> updateSlot(HarvestSlotRecord slot) async {
    try {
      return await ApiService.putData<HarvestSlotRecord>(
        '/owner/harvest-slots/${slot.slotId}',
        requiresAuth: true,
        body: {
          'farm_id': slot.farmId,
          'product_id': slot.productId,
          'prediction_id': slot.predictionId,
          'confirmed_harvest_start': slot.confirmedHarvestStart,
          'confirmed_harvest_end': slot.confirmedHarvestEnd,
          'confirmed_reservable_kg': slot.confirmedReservableKg,
          'confirmed_price': slot.confirmedPrice,
          'customer_notice': slot.customerNotice,
          'slot_status': slot.slotStatus,
        },
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return HarvestSlotRecord.fromJson(json);
        },
      );
    } catch (_) {
      return slot;
    }
  }

  List<HarvestProductOption> _fallbackProductOptions() {
    const farm = OwnerFarmRecord(
      farmId: 3,
      farmName: '청주 햇살농원',
      farmRegion: '충북 청주',
      farmAddress: '충청북도 청주시 상당구 낭성면 산성로 120',
      farmImageUrl: 'assets/images/owner_demo/chungju_apple_farm.png',
    );
    return const [
      HarvestProductOption(
        farm: farm,
        product: ProductRecord(
          '양광 사과',
          '5kg 박스',
          39000,
          6,
          '판매 중',
          Color(0xffDFF4E8),
          id: 5,
          farmId: 3,
          variety: '양광',
          imageUrl: 'assets/images/owner_demo/demo_yanggwang_product.png',
        ),
      ),
      HarvestProductOption(
        farm: farm,
        product: ProductRecord(
          '부사 사과',
          '3kg 박스',
          32000,
          5,
          '판매 중',
          Color(0xffDFF4E8),
          id: 6,
          farmId: 3,
          variety: '부사',
          imageUrl: 'assets/images/owner_demo/demo_fuji_product.png',
        ),
      ),
    ];
  }

  HarvestPredictionRecord _fallbackPrediction(
    HarvestProductOption option, {
    required int pastYieldKg,
    required String recentWeather,
    required String cultivationStatus,
  }) {
    final now = DateTime.now();
    final weatherFactor = switch (recentWeather) {
      '고온' => 0.94,
      '저온' => 0.90,
      '강수 많음' => 0.88,
      _ => 1.0,
    };
    final statusFactor = switch (cultivationStatus) {
      '관수 필요' => 0.92,
      '병해 확인' => 0.84,
      _ => 1.0,
    };
    final estimated = (pastYieldKg * weatherFactor * statusFactor).round();
    return HarvestPredictionRecord(
      predictionId: 9901,
      farmId: option.farm.farmId,
      productId: option.product.id ?? 0,
      predictedHarvestStart: now.add(const Duration(days: 5)).toIso8601String(),
      predictedHarvestEnd: now.add(const Duration(days: 9)).toIso8601String(),
      estimatedYieldKg: estimated.toDouble(),
      suggestedReservableMinKg: estimated * 0.48,
      suggestedReservableMaxKg: estimated * 0.62,
      recommendedPrice: option.product.price,
      confidence: cultivationStatus == '양호' ? 0.88 : 0.74,
      warningMessage: '최근 기상과 생육 입력값을 반영한 보수적 예측입니다.',
    );
  }

  List<HarvestSlotRecord> _fallbackSlots() {
    final now = DateTime.now();
    return [
      HarvestSlotRecord(
        slotId: 9901,
        productName: '양광 사과',
        slotStatus: 'OPEN',
        confirmedHarvestStart: now
            .add(const Duration(days: 3))
            .toIso8601String(),
        confirmedHarvestEnd: now.add(const Duration(days: 7)).toIso8601String(),
        confirmedReservableKg: 420,
        reservedKg: 160,
        soldKg: 90,
        availableKg: 170,
        confirmedPrice: 39000,
        customerNotice: '양광 사과 예약 수량을 제한 오픈했습니다.',
        farmId: 3,
        productId: 5,
        farmName: '청주 햇살농원',
        imageUrl: 'assets/images/owner_demo/demo_yanggwang_product.png',
        packageUnitKg: 5,
        predictionId: 9901,
      ),
    ];
  }
}

class _MlClimateFeatures {
  const _MlClimateFeatures({
    required this.marAvgTemp,
    required this.augSunshine,
    required this.octRainfall,
    required this.augHumidity,
  });

  final double marAvgTemp;
  final double augSunshine;
  final double octRainfall;
  final double augHumidity;

  _MlClimateFeatures copyWith({
    double? marAvgTemp,
    double? augSunshine,
    double? octRainfall,
    double? augHumidity,
  }) {
    return _MlClimateFeatures(
      marAvgTemp: marAvgTemp ?? this.marAvgTemp,
      augSunshine: augSunshine ?? this.augSunshine,
      octRainfall: octRainfall ?? this.octRainfall,
      augHumidity: augHumidity ?? this.augHumidity,
    );
  }
}
