import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/customer_model.dart';

class CustomersRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<CustomerModel>> getCustomers({String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _apiClient.dio.get(
        ApiConstants.customers,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final List list = response.data['data'] ?? response.data ?? [];
      return list.map((e) => CustomerModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('فشل جلب العملاء: $e');
    }
  }

  Future<CustomerModel> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.customers,
        data: {
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
          if (address != null && address.isNotEmpty) 'address': address,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
      return CustomerModel.fromJson(data);
    } catch (e) {
      throw Exception('فشل إضافة العميل: $e');
    }
  }

  Future<CustomerModel> updateCustomer({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (email != null) data['email'] = email;
      if (address != null) data['address'] = address;
      final response = await _apiClient.dio.put(
        ApiConstants.customerById(id),
        data: data,
      );
      final result = response.data['data'] as Map<String, dynamic>? ?? response.data;
      return CustomerModel.fromJson(result);
    } catch (e) {
      throw Exception('فشل تحديث العميل: $e');
    }
  }
}
