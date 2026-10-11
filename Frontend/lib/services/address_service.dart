import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/user_address.dart';

String _messageFromDioError(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }
  return fallback;
}

class AddressService {
  /// Fetch all addresses of the authenticated customer.
  Future<List<UserAddress>> getAddresses() async {
    try {
      final response = await ApiClient.dio.get('/addresses');
      final data = response.data as List;
      return data
          .map((json) => UserAddress.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Gagal memuat daftar alamat.'));
    }
  }

  /// Create a new address.
  Future<UserAddress> createAddress({
    required String label,
    String? receiverName,
    String? phone,
    required String fullAddress,
    String? notes,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/addresses',
        data: {
          'label': label,
          if (receiverName != null && receiverName.trim().isNotEmpty)
            'receiverName': receiverName.trim(),
          if (phone != null && phone.trim().isNotEmpty)
            'phone': phone.trim(),
          'fullAddress': fullAddress.trim(),
          if (notes != null && notes.trim().isNotEmpty)
            'notes': notes.trim(),
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          'isDefault': isDefault,
        },
      );
      return UserAddress.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Gagal menambahkan alamat.'));
    }
  }

  /// Update an existing address.
  Future<UserAddress> updateAddress({
    required int id,
    String? label,
    String? receiverName,
    String? phone,
    String? fullAddress,
    String? notes,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      final response = await ApiClient.dio.put(
        '/addresses/$id',
        data: {
          if (label != null) 'label': label.trim(),
          if (receiverName != null) 'receiverName': receiverName.trim(),
          if (phone != null) 'phone': phone.trim(),
          if (fullAddress != null) 'fullAddress': fullAddress.trim(),
          if (notes != null) 'notes': notes.trim(),
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (isDefault != null) 'isDefault': isDefault,
        },
      );
      return UserAddress.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Gagal memperbarui alamat.'));
    }
  }

  /// Mark an address as the default address.
  Future<UserAddress> setDefaultAddress(int id) async {
    try {
      final response = await ApiClient.dio.patch('/addresses/$id/default');
      return UserAddress.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Gagal mengatur alamat utama.'));
    }
  }

  /// Delete an address.
  Future<void> deleteAddress(int id) async {
    try {
      await ApiClient.dio.delete('/addresses/$id');
    } on DioException catch (e) {
      throw Exception(_messageFromDioError(e, 'Gagal menghapus alamat.'));
    }
  }
}
