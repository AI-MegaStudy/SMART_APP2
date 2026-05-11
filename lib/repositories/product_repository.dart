import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:smart_app/core/api_service.dart';
import 'package:smart_app/model/product_record.dart';

class ProductRepository {
  Future<List<OwnerFarmRecord>> fetchOwnerFarms() async {
    try {
      final farms = await ApiService.getData<List<OwnerFarmRecord>>(
        '/owner/farms/me',
        requiresAuth: true,
        parser: (data) {
          final list = data as List<dynamic>? ?? const [];
          return [
            for (final item in list)
              OwnerFarmRecord.fromJson(
                item as Map<String, dynamic>? ?? const {},
              ),
          ];
        },
      );
      return farms.isEmpty ? _fallbackFarms : farms;
    } catch (_) {
      return _fallbackFarms;
    }
  }

  Future<List<ProductRecord>> fetchOwnerProducts() async {
    try {
      final products = await ApiService.getData<List<ProductRecord>>(
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
      return products.isEmpty ? _fallbackProducts : products;
    } catch (_) {
      return _fallbackProducts;
    }
  }

  Future<OwnerFarmRecord> updateFarm(OwnerFarmRecord farm) async {
    try {
      final body = <String, Object?>{
        'farm_name': farm.farmName,
        'farm_region': farm.farmRegion,
        'farm_address': farm.farmAddress,
        'farm_description': farm.farmDescription,
        'delivery_policy': farm.deliveryPolicy,
        'return_policy': farm.returnPolicy,
      };
      if (_isPersistedImageUrl(farm.farmImageUrl)) {
        body['farm_image_url'] = farm.farmImageUrl;
      }
      return await ApiService.putData<OwnerFarmRecord>(
        '/owner/farms/${farm.farmId}',
        requiresAuth: true,
        body: body,
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return OwnerFarmRecord.fromJson(json);
        },
      );
    } catch (_) {
      return farm;
    }
  }

  Future<OwnerFarmRecord> uploadFarmImage({
    required int farmId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final uploadName = _safeImageUploadName(
      'farm_$farmId',
      fileName,
      fileBytes,
    );
    try {
      final uploaded = await ApiService.postMultipartData<OwnerFarmRecord>(
        '/owner/farms/$farmId/image',
        requiresAuth: true,
        fileField: 'file',
        fileName: uploadName,
        fileBytes: fileBytes,
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return OwnerFarmRecord.fromJson(json);
        },
      );
      debugPrint(
        '[API 정상][farm.image] farmId=$farmId file=$uploadName url=${uploaded.farmImageUrl}',
      );
      return uploaded;
    } catch (error) {
      debugPrint(
        '[API 실패][farm.image] farmId=$farmId file=$uploadName error=$error',
      );
      rethrow;
    }
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
  }) async {
    try {
      return await ApiService.postData<ProductRecord>(
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
    } catch (_) {
      return ProductRecord(
        productName,
        ProductRecord.packageLabel(packageUnitKg),
        basePrice,
        0,
        ProductRecord.statusLabel(productStatus),
        ProductRecord.statusColor(ProductRecord.statusLabel(productStatus)),
        id: DateTime.now().millisecondsSinceEpoch,
        farmId: farmId,
        fruitType: fruitType,
        variety: variety,
        description: productDescription,
        imageUrl: variety == '부사'
            ? 'assets/images/owner_demo/demo_fuji_product.png'
            : 'assets/images/owner_demo/demo_yanggwang_product.png',
      );
    }
  }

  Future<ProductRecord> updateProduct(ProductRecord product) async {
    final productId = product.id;
    final farmId = product.farmId;
    if (productId == null || farmId == null) {
      return product.copyWith(
        id: productId ?? DateTime.now().millisecondsSinceEpoch,
        farmId: farmId ?? _fallbackFarms.first.farmId,
      );
    }
    try {
      final body = <String, Object?>{
        'farm_id': farmId,
        'product_name': product.name,
        'fruit_type': product.fruitType,
        'variety': product.variety.isEmpty ? product.name : product.variety,
        'package_unit_kg': product.packageUnitKg,
        'base_price': product.price,
        'product_status': product.backendStatus,
        'product_description': product.description,
      };
      if (_isPersistedImageUrl(product.imageUrl)) {
        body['image_url'] = product.imageUrl;
      }
      return await ApiService.putData<ProductRecord>(
        '/owner/products/$productId',
        requiresAuth: true,
        body: body,
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return ProductRecord.fromJson(json);
        },
      );
    } catch (_) {
      return product;
    }
  }

  Future<ProductRecord> updateProductStatus({
    required int productId,
    required String productStatus,
  }) async {
    try {
      return await ApiService.patchData<ProductRecord>(
        '/owner/products/$productId/status',
        requiresAuth: true,
        body: {'product_status': productStatus},
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return ProductRecord.fromJson(json);
        },
      );
    } catch (_) {
      final current = _fallbackProducts.firstWhere(
        (product) => product.id == productId,
        orElse: () => _fallbackProducts.first,
      );
      return current.copyWith(status: ProductRecord.statusLabel(productStatus));
    }
  }

  Future<ProductRecord> uploadProductImage({
    required int productId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final uploadName = _safeImageUploadName(
      'product_$productId',
      fileName,
      fileBytes,
    );
    try {
      final uploaded = await ApiService.postMultipartData<ProductRecord>(
        '/owner/products/$productId/image',
        requiresAuth: true,
        fileField: 'file',
        fileName: uploadName,
        fileBytes: fileBytes,
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return ProductRecord.fromJson(json);
        },
      );
      debugPrint(
        '[API 정상][product.image] productId=$productId file=$uploadName url=${uploaded.imageUrl}',
      );
      return uploaded;
    } catch (error) {
      debugPrint(
        '[API 실패][product.image] productId=$productId file=$uploadName error=$error',
      );
      rethrow;
    }
  }
}

bool _isPersistedImageUrl(String? value) {
  final lower = value?.trim().toLowerCase() ?? '';
  return lower.startsWith('http://') || lower.startsWith('https://');
}

String _safeImageUploadName(
  String prefix,
  String originalFileName,
  Uint8List fileBytes,
) {
  final extension = _imageExtension(fileBytes, originalFileName);
  return '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$extension';
}

String _imageExtension(Uint8List bytes, String fileName) {
  if (bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'jpg';
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38) {
    return 'gif';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'webp';
  }

  final extension = fileName.split('.').last.toLowerCase();
  return switch (extension) {
    'jpeg' => 'jpg',
    'jpg' || 'png' || 'gif' || 'webp' => extension,
    _ => 'jpg',
  };
}

const _fallbackFarms = [
  OwnerFarmRecord(
    farmId: 3,
    farmName: '청주 햇살농원',
    farmRegion: '충북 청주',
    farmAddress: '충청북도 청주시 상당구 낭성면 산성로 120',
    farmImageUrl: 'assets/images/owner_demo/chungju_apple_farm.png',
    farmDescription: '양광과 부사를 선별 수확해 당일 포장하는 직거래 농장입니다.',
    deliveryPolicy: '수확 후 24시간 이내 선별 포장, 오전 주문은 당일 출고합니다.',
    returnPolicy: '상품 하자 이미지를 확인한 뒤 동일 상품 재발송 또는 환불 처리합니다.',
  ),
];

const _fallbackProducts = [
  ProductRecord(
    '양광 사과',
    '5kg 박스',
    39000,
    42,
    '판매 중',
    Color(0xffDFF4E8),
    id: 301,
    farmId: 3,
    fruitType: '사과',
    variety: '양광',
    description: '산미와 단맛 균형이 좋은 선물용 양광 사과입니다.',
    imageUrl: 'assets/images/owner_demo/demo_yanggwang_product.png',
  ),
  ProductRecord(
    '부사 사과',
    '3kg 박스',
    32000,
    28,
    '판매 중',
    Color(0xffDFF4E8),
    id: 302,
    farmId: 3,
    fruitType: '사과',
    variety: '부사',
    description: '아삭한 식감과 저장성이 좋은 가정용 부사 사과입니다.',
    imageUrl: 'assets/images/owner_demo/demo_fuji_product.png',
  ),
];
