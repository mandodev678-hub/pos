import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/order_model.dart';

class OrdersRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<OrderModel>> getOrders({
    String? status,
    String? date,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) params['status'] = status;
      if (date != null) params['date'] = date;
      final response = await _apiClient.dio.get(
        ApiConstants.orders,
        queryParameters: params,
      );
      final List list = response.data['data'] ?? response.data ?? [];
      return list.map((e) => OrderModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('فشل جلب الطلبات: $e');
    }
  }

  Future<Map<String, dynamic>> getDailySummary({String? date}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.reportsDaily,
        queryParameters: date != null ? {'date': date} : null,
      );
      return response.data['data'] ?? response.data ?? {};
    } catch (e) {
      throw Exception('فشل جلب تقرير اليوم: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBestSellers() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.reportsBestSellers);
      final List list = response.data['data'] ?? response.data ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('فشل جلب الأكثر مبيعاً: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStaffPerformance({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;
      final response = await _apiClient.dio.get(
        ApiConstants.reportsStaffPerformance,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final List list = response.data['data'] ?? response.data ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('فشل جلب تقرير أداء الموظفين: $e');
    }
  }

  Future<Map<String, dynamic>> getRangeReport({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.reportsRange,
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
        },
      );
      return response.data['data'] ?? response.data ?? {};
    } catch (e) {
      throw Exception('فشل جلب التقرير المالي للفترة: $e');
    }
  }

  Future<Map<String, dynamic>> getDailyReconciliation({String? date}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.reportsReconciliationDaily,
        queryParameters: date != null ? {'date': date} : null,
      );
      return response.data['data'] ?? response.data ?? {};
    } catch (e) {
      throw Exception('فشل جلب تقرير المطابقة اليومية: $e');
    }
  }
}
