import 'dart:typed_data';

import 'package:smart_app/core/api_service.dart';
import 'package:smart_app/model/product_record.dart';

class ProductRepository {
  Future<List<OwnerFarmRecord>> fetchOwnerFarms() {
    return ApiService.getData<List<OwnerFarmRecord>>(
      '/owner/farms/me',
      requiresAuth: true,
      parser: (data) {
        final list = data as List<dynamic>? ?? const [];
        return [
          for (final item in list)
            OwnerFarmRecord.fromJson(item as Map<String, dynamic>? ?? const {}),
        ];
      },
    );
  }

  Future<List<ProductRecord>> fetchOwnerProducts() {
    return ApiService.getData<List<ProductRecord>>(
      '/owner/products',
      requiresAuth: true,
      parser: (data) {
        final list = data as List<dynamic>? ?? const [];
        return [
          for (final item in list)
            ProductRecord.fromJson(item as Map<String, dynamic>? ?? const {}),
        ];
      },
    );
  }

  Future<OwnerFarmRecord> updateFarm(OwnerFarmRecord farm) {
    return ApiService.putData<OwnerFarmRecord>(
      '/owner/farms/${farm.farmId}',
      requiresAuth: true,
      body: {
        'farm_name': farm.farmName,
        'farm_region': farm.farmRegion,
        'farm_address': farm.farmAddress,
        'farm_image_url': farm.farmImageUrl,
        'farm_description': farm.farmDescription,
        'delivery_policy': farm.deliveryPolicy,
        'return_policy': farm.returnPolicy,
      },
      parser: (data) {
        final json = data as Map<String, dynamic>? ?? const {};
        return OwnerFarmRecord.fromJson(json);
      },
    );
  }

  Future<OwnerFarmRecord> uploadFarmImage({
    required int farmId,
    required String fileName,
    required Uint8List fileBytes,
  }) {
    return ApiService.postMultipartData<OwnerFarmRecord>(
      '/owner/farms/$farmId/image',
      requiresAuth: true,
      fileField: 'file',
      fileName: fileName,
      fileBytes: fileBytes,
      parser: (data) {
        final json = data as Map<String, dynamic>? ?? const {};
        return OwnerFarmRecord.fromJson(json);
      },
    );
  }

  Future<ProductRecord> createProduct({
    required int farmId,
    required String productName,
    required String fruitType,
    required String variety,
    required double packageUnitKg,
    required int basePrice,
    required String productStatus,
    String? productDescription,
  }) {
    return ApiService.postData<ProductRecord>(
      '/owner/products',
      requiresAuth: true,
      body: {
        'farm_id': farmId,
        'product_name': productName,
        'fruit_type': fruitType,
        'variety': variety,
        'package_unit_kg': packageUnitKg,
        'base_price': basePrice,
        'product_status': productStatus,
        'product_description': productDescription,
      },
      parser: (data) {
        final json = data as Map<String, dynamic>? ?? const {};
        return ProductRecord.fromJson(json);
      },
    );
  }

  Future<ProductRecord> updateProduct(ProductRecord product) {
    final productId = product.id;
    final farmId = product.farmId;
    if (productId == null || farmId == null) {
      throw ArgumentError('상품 ID와 농장 ID가 필요합니다.');
    }
    return ApiService.putData<ProductRecord>(
      '/owner/products/$productId',
      requiresAuth: true,
      body: {
        'farm_id': farmId,
        'product_name': product.name,
        'fruit_type': product.fruitType,
        'variety': product.variety.isEmpty ? product.name : product.variety,
        'package_unit_kg': product.packageUnitKg,
        'base_price': product.price,
        'product_status': product.backendStatus,
        'product_description': product.description,
        'image_url': product.imageUrl,
      },
      parser: (data) {
        final json = data as Map<String, dynamic>? ?? const {};
        return ProductRecord.fromJson(json);
      },
    );
  }

  Future<ProductRecord> updateProductStatus({
    required int productId,
    required String productStatus,
  }) {
    return ApiService.patchData<ProductRecord>(
      '/owner/products/$productId/status',
      requiresAuth: true,
      body: {'product_status': productStatus},
      parser: (data) {
        final json = data as Map<String, dynamic>? ?? const {};
        return ProductRecord.fromJson(json);
      },
    );
  }

  Future<ProductRecord> uploadProductImage({
    required int productId,
    required String fileName,
    required Uint8List fileBytes,
  }) {
    return ApiService.postMultipartData<ProductRecord>(
      '/owner/products/$productId/image',
      requiresAuth: true,
      fileField: 'file',
      fileName: fileName,
      fileBytes: fileBytes,
      parser: (data) {
        final json = data as Map<String, dynamic>? ?? const {};
        return ProductRecord.fromJson(json);
      },
    );
  }
}
