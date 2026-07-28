import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/shift_model.dart';

class ShiftRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ShiftModel?> getCurrentShift() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.currentShift);
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ShiftModel.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<ShiftModel> openShift(double startingCash) async {
    final response = await _apiClient.dio.post(
      ApiConstants.openShift,
      data: {'starting_cash': startingCash},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null) return ShiftModel.fromJson(data);
      return ShiftModel.fromJson(response.data);
    }
    throw Exception(response.data['message'] ?? 'فشل فتح الوردية');
  }

  Future<Map<String, dynamic>> closeShift(double endingCash, String? notes) async {
    final response = await _apiClient.dio.post(
      ApiConstants.closeShift,
      data: {
        'ending_cash': endingCash,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    if (response.statusCode == 200) {
      return response.data['data'] as Map<String, dynamic>? ?? response.data;
    }
    throw Exception(response.data['message'] ?? 'فشل إغلاق الوردية');
  }
}
