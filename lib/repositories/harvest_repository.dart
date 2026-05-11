import 'package:flutter/material.dart';
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
          if (product.id != null && product.farmId != null)
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
      return options.isEmpty ? _fallbackProductOptions() : options;
    } catch (_) {
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
      return await ApiService.postData<HarvestPredictionRecord>(
        '/owner/ml/predictions',
        requiresAuth: true,
        body: {
          'farm_id': option.farm.farmId,
          'product_id': option.product.id,
          'features': {
            'past_yield_kg': pastYieldKg,
            'suggested_price': option.product.price,
            'package_unit_kg': option.product.packageUnitKg,
            'open_slot_count': option.product.stockKg,
            'variety': option.product.variety,
            'recent_weather': recentWeather,
            'cultivation_status': cultivationStatus,
          },
        },
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return HarvestPredictionRecord.fromJson(json);
        },
      );
    } catch (_) {
      return _fallbackPrediction(
        option,
        pastYieldKg: pastYieldKg,
        recentWeather: recentWeather,
        cultivationStatus: cultivationStatus,
      );
    }
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
      return slots;
    } catch (_) {
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
      farmName: 'cheng80 테스트 농장',
      farmRegion: '충북 충주',
      farmAddress: '충북 충주시 사과로 80',
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
          imageUrl: 'assets/images/owner_demo/yanggwang_apples.png',
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
          imageUrl: 'assets/images/owner_demo/fuji_apples.png',
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
      warningMessage: 'API 연결 상태와 무관하게 발표용 예측값을 표시합니다.',
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
        farmName: 'cheng80 테스트 농장',
        imageUrl: 'assets/images/owner_demo/yanggwang_apples.png',
        packageUnitKg: 5,
        predictionId: 9901,
      ),
    ];
  }
}
