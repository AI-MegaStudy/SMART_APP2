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
    HarvestProductOption option,
  ) {
    return ApiService.postData<HarvestPredictionRecord>(
      '/owner/ml/predictions',
      requiresAuth: true,
      body: {
        'farm_id': option.farm.farmId,
        'product_id': option.product.id,
        'features': {
          'past_yield_kg': 420,
          'suggested_price': option.product.price,
          'package_unit_kg': option.product.packageUnitKg,
          'variety': option.product.variety,
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
  }) {
    return ApiService.postData<HarvestSlotRecord>(
      '/owner/harvest-slots',
      requiresAuth: true,
      body: {
        'farm_id': option.farm.farmId,
        'product_id': option.product.id,
        'prediction_id': prediction.predictionId,
        'confirmed_harvest_start': prediction.predictedHarvestStart,
        'confirmed_harvest_end': prediction.predictedHarvestEnd,
        'confirmed_reservable_kg': prediction.suggestedReservableMaxKg,
        'confirmed_price': prediction.recommendedPrice,
        'customer_notice': '${option.product.name} 예약 가능 수량을 열었습니다.',
        'slot_status': 'OPEN',
      },
      parser: (data) {
        final json = data as Map<String, dynamic>? ?? const {};
        return HarvestSlotRecord.fromJson(json);
      },
    );
  }
}
