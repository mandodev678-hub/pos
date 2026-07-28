import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class TransfersRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getTransfers({
    String? warehouseId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'offset': offset};
      if (warehouseId != null) params['warehouse_id'] = warehouseId;
      if (status != null) params['status'] = status;
      final response = await _apiClient.dio.get(
        ApiConstants.transfers,
        queryParameters: params,
      );
      final List list = response.data['data'] ?? response.data ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('فشل جلب التحويلات: $e');
    }
  }

  Future<Map<String, dynamic>> getTransferById(String id) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.transferById(id));
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل جلب بيانات التحويل: $e');
    }
  }

  Future<Map<String, dynamic>> createTransfer({
    required String fromWarehouseId,
    required String toWarehouseId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.transfers,
        data: {
          'from_warehouse_id': fromWarehouseId,
          'to_warehouse_id': toWarehouseId,
          'items': items,
          'notes': ?notes,
        },
      );
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل إنشاء التحويل: $e');
    }
  }

  Future<Map<String, dynamic>> confirmTransfer(String id) async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.confirmTransfer(id));
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('فشل تأكيد التحويل: $e');
    }
  }

  Future<void> cancelTransfer(String id, {String? reason}) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.cancelTransfer(id),
        data: {'reason': ?reason},
      );
    } catch (e) {
      throw Exception('فشل إلغاء التحويل: $e');
    }
  }
}
