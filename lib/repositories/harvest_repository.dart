import 'package:smart_app/core/api_service.dart';
import 'package:smart_app/model/harvest_slot_record.dart';
import 'package:smart_app/model/product_record.dart';
import 'package:smart_app/repositories/product_repository.dart';

class HarvestRepository {
  HarvestRepository({ProductRepository? productRepository})
    : productRepository = productRepository ?? ProductRepository();

  final ProductRepository productRepository;

  Future<List<HarvestProductOption>> fetchProductOptions() async {
    final farms = await productRepository.fetchOwnerFarms();
    final products = await productRepository.fetchOwnerProducts();
    return [
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
  }

  Future<HarvestPredictionRecord> createPrediction(
    HarvestProductOption option, {
    required int pastYieldKg,
    required String recentWeather,
    required String cultivationStatus,
  }) {
    return ApiService.postData<HarvestPredictionRecord>(
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
  }

  Future<HarvestSlotRecord> createOpenSlot({
    required HarvestProductOption option,
    required HarvestPredictionRecord prediction,
    required String confirmedHarvestStart,
    required String confirmedHarvestEnd,
    required int confirmedReservableKg,
    required int confirmedPrice,
    required String customerNotice,
  }) {
    return ApiService.postData<HarvestSlotRecord>(
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
  }

  Future<List<HarvestSlotRecord>> fetchOwnerSlots() {
    return ApiService.getData<List<HarvestSlotRecord>>(
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
  }

  Future<HarvestSlotRecord> updateSlotStatus({
    required int slotId,
    required String status,
  }) {
    return ApiService.patchData<HarvestSlotRecord>(
      '/owner/harvest-slots/$slotId/status',
      requiresAuth: true,
      body: {'slot_status': status},
      parser: (data) {
        final json = data as Map<String, dynamic>? ?? const {};
        return HarvestSlotRecord.fromJson(json);
      },
    );
  }

  Future<HarvestSlotRecord> updateSlot(HarvestSlotRecord slot) {
    return ApiService.putData<HarvestSlotRecord>(
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
  }
}
