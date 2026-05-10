class OwnerProfile {
  const OwnerProfile({
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.email,
    required this.accountStatus,
    this.businessNumber,
  });

  final int ownerId;
  final String ownerName;
  final String ownerPhone;
  final String email;
  final String accountStatus;
  final String? businessNumber;

  factory OwnerProfile.fromJson(Map<String, dynamic> json) {
    return OwnerProfile(
      ownerId: _asInt(json['owner_id']),
      ownerName: json['owner_name']?.toString() ?? '',
      ownerPhone: json['owner_phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      accountStatus: json['account_status']?.toString() ?? '',
      businessNumber: json['business_number']?.toString(),
    );
  }

  OwnerProfile copyWith({
    String? ownerName,
    String? ownerPhone,
    String? businessNumber,
  }) {
    return OwnerProfile(
      ownerId: ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      email: email,
      accountStatus: accountStatus,
      businessNumber: businessNumber ?? this.businessNumber,
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
