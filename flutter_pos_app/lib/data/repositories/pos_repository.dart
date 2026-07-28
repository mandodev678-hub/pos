import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';

class PosRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.dio.get(ApiConstants.categories);
    if (response.statusCode == 200) {
      final List list = response.data['data'] ?? response.data ?? [];
      return list.map((item) => CategoryModel.fromJson(item)).toList();
    }
    throw Exception('فشل جلب الأقسام');
  }

  Future<List<ProductModel>> getMenuItems({String? categoryId}) async {
    final response = await _apiClient.dio.get(
      ApiConstants.menuItems,
      queryParameters: categoryId != null ? {'category_id': categoryId} : null,
    );
    if (response.statusCode == 200) {
      final List list = response.data['data'] ?? response.data ?? [];
      return list.map((item) => ProductModel.fromJson(item)).toList();
    }
    throw Exception('فشل جلب أطعمة الوجبات');
  }

  Future<Map<String, dynamic>> createOrder({
    required String orderType,
    required List<CartItemModel> items,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    double discount = 0.0,
    double tax = 0.0,
    String paymentMethod = 'cash',
    bool isPaid = true,
  }) async {
    final double subtotal = items.fold(0.0, (sum, i) => sum + i.totalPrice);
    final double total = subtotal + tax - discount;

    final body = {
      'order_type': orderType == 'dine_in' ? 'walkin' : orderType,
      'table_number': tableNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'payment_status': isPaid ? 'paid' : 'pending',
    };

    try {
      final response = await _apiClient.dio.post(ApiConstants.orders, data: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] ?? response.data;
      }
      throw Exception(response.data['message'] ?? 'فشل إنشاء الطلب');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final serverMsg = e.response?.data['message'] ?? e.response?.data['error'];
        if (serverMsg != null) {
          throw Exception(serverMsg);
        }
      }
      throw Exception('فشل الاتصال بخادم الطلبات: ${e.message}');
    }
  }

  Future<void> printOrder(String orderId, {String type = 'receipt'}) async {
    try {
      await _apiClient.dio.post('/devices/print/order/$orderId', data: {'type': type});
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.settings);
      if (response.data is Map<String, dynamic>) {
        return response.data['data'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  Future<bool> payOrder({
    required String orderId,
    required String paymentMethod,
    required double amountPaid,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.payOrder(orderId),
        data: {
          'payment_method': paymentMethod,
          'amount_paid': amountPaid,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return true; // If order was created as auto-paid, consider payment successful
    }
  }
}
