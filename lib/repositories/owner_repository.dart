import 'package:smart_app/core/api_service.dart';
import 'package:smart_app/model/owner_profile.dart';

class OwnerRepository {
  Future<OwnerProfile> fetchProfile() {
    return ApiService.getData<OwnerProfile>(
      '/owner/profile',
      requiresAuth: true,
      parser: (data) {
        final json = data as Map<String, dynamic>? ?? const {};
        return OwnerProfile.fromJson(json);
      },
    );
  }

  Future<OwnerProfile> updateProfile({
    required String ownerName,
    required String ownerPhone,
    String? businessNumber,
  }) {
    return ApiService.putData<OwnerProfile>(
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
  }
}
