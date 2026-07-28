import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/table_model.dart';

class TableRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<TableModel>> getTables() async {
    final response = await _apiClient.dio.get(ApiConstants.tables);
    if (response.statusCode == 200) {
      final List list = response.data['data'] ?? response.data ?? [];
      return list.map((item) => TableModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('فشل جلب طاولات الصالة');
  }

  Future<TableModel> createTable({
    required String tableNumber,
    int capacity = 4,
    String area = 'صالة',
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.tables,
      data: {
        'table_number': tableNumber,
        'capacity': capacity,
        'area': area,
      },
    );
    if (response.statusCode == 201) {
      return TableModel.fromJson(response.data['data'] as Map<String, dynamic>);
    }
    throw Exception(response.data['message'] ?? 'فشل إضافة الطاولة');
  }

  Future<TableModel> updateTable({
    required String id,
    String? tableNumber,
    int? capacity,
    String? area,
    String? status,
  }) async {
    final data = <String, dynamic>{};
    if (tableNumber != null) data['table_number'] = tableNumber;
    if (capacity != null) data['capacity'] = capacity;
    if (area != null) data['area'] = area;
    if (status != null) data['status'] = status;

    final response = await _apiClient.dio.put(
      ApiConstants.tableById(id),
      data: data,
    );
    if (response.statusCode == 200) {
      return TableModel.fromJson(response.data['data'] as Map<String, dynamic>);
    }
    throw Exception(response.data['message'] ?? 'فشل تحديث الطاولة');
  }

  Future<void> deleteTable(String id) async {
    final response = await _apiClient.dio.delete(ApiConstants.tableById(id));
    if (response.statusCode != 200) {
      throw Exception(response.data['message'] ?? 'فشل حذف الطاولة');
    }
  }

  Future<Map<String, dynamic>> transferOrder({
    required String sourceTableId,
    required String targetTableNumber,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.transferTable(sourceTableId),
      data: {'target_table': targetTableNumber},
    );
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.data['message'] ?? 'فشل نقل الطلب');
  }

  Future<void> clearTable(String id) async {
    final response = await _apiClient.dio.delete(ApiConstants.clearTable(id));
    if (response.statusCode != 200) {
      throw Exception(response.data['message'] ?? 'فشل تفريغ الطاولة');
    }
  }
}
