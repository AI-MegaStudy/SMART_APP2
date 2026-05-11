import 'package:smart_app/core/api_service.dart';
import 'package:smart_app/model/owner_profile.dart';

class OwnerRepository {
  Future<OwnerProfile> fetchProfile() async {
    try {
      return await ApiService.getData<OwnerProfile>(
        '/owner/profile',
        requiresAuth: true,
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return OwnerProfile.fromJson(json);
        },
      );
    } catch (_) {
      return _fallbackProfile;
    }
  }

  Future<OwnerProfile> updateProfile({
    required String ownerName,
    required String ownerPhone,
    String? businessNumber,
  }) async {
    try {
      return await ApiService.putData<OwnerProfile>(
        '/owner/profile',
        requiresAuth: true,
        body: {
          'owner_name': ownerName,
          'owner_phone': ownerPhone,
          'business_number': businessNumber?.isEmpty == true
              ? null
              : businessNumber,
        },
        parser: (data) {
          final json = data as Map<String, dynamic>? ?? const {};
          return OwnerProfile.fromJson(json);
        },
      );
    } catch (_) {
      return _fallbackProfile.copyWith(
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        businessNumber: businessNumber,
      );
    }
  }
}

const _fallbackProfile = OwnerProfile(
  ownerId: 3,
  ownerName: '청주 햇살농원',
  ownerPhone: '01012345678',
  email: 'cheng80@gmail.com',
  accountStatus: 'ACTIVE',
  businessNumber: '1234567890',
);
