import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class SettingsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.settings);
      if (response.data is Map<String, dynamic>) {
        return response.data['data'] as Map<String, dynamic>? ?? response.data;
      }
      return {};
    } catch (e) {
      debugPrint('❌ SettingsRepository.getSettings error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(ApiConstants.settings, data: data);
      if (response.data is Map<String, dynamic>) {
        return response.data['data'] as Map<String, dynamic>? ?? response.data;
      }
      return {};
    } catch (e) {
      debugPrint('❌ SettingsRepository.updateSettings error: $e');
      rethrow;
    }
  }
}
