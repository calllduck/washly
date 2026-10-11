class UserAddress {
  final int id;
  final int userId;
  final String label;
  final String? receiverName;
  final String? phone;
  final String fullAddress;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.userId,
    required this.label,
    this.receiverName,
    this.phone,
    required this.fullAddress,
    this.notes,
    this.latitude,
    this.longitude,
    required this.isDefault,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as int,
      userId: json['userId'] as int,
      label: json['label'] as String? ?? '',
      receiverName: json['receiverName'] as String?,
      phone: json['phone'] as String?,
      fullAddress: json['fullAddress'] as String? ?? '',
      notes: json['notes'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      if (receiverName != null && receiverName!.isNotEmpty)
        'receiverName': receiverName,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'fullAddress': fullAddress,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'isDefault': isDefault,
    };
  }

  UserAddress copyWith({
    int? id,
    int? userId,
    String? label,
    String? receiverName,
    String? phone,
    String? fullAddress,
    String? notes,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return UserAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      receiverName: receiverName ?? this.receiverName,
      phone: phone ?? this.phone,
      fullAddress: fullAddress ?? this.fullAddress,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
