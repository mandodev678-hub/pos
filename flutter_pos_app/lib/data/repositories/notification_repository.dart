import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient = ApiClient();

  Future<({List<NotificationModel> notifications, int unreadCount})> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'offset': offset};
      if (unreadOnly) params['unread_only'] = 'true';

      final response = await _apiClient.dio.get(
        ApiConstants.notifications,
        queryParameters: params,
      );
      final data = response.data;
      final List list = (data['data'] as List?) ?? [];
      final unreadCount = (data['unread_count'] as int?) ?? 0;
      final notifications = list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
      return (notifications: notifications, unreadCount: unreadCount);
    } catch (e) {
      debugPrint('❌ NotificationRepository.getNotifications error: $e');
      return (notifications: <NotificationModel>[], unreadCount: 0);
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      await _apiClient.dio.put(ApiConstants.notificationRead(id));
      return true;
    } catch (e) {
      debugPrint('❌ NotificationRepository.markAsRead error: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _apiClient.dio.put(ApiConstants.notificationReadAll);
      return true;
    } catch (e) {
      debugPrint('❌ NotificationRepository.markAllAsRead error: $e');
      return false;
    }
  }

  Future<bool> cleanup() async {
    try {
      await _apiClient.dio.delete(ApiConstants.notificationCleanup);
      return true;
    } catch (e) {
      debugPrint('❌ NotificationRepository.cleanup error: $e');
      return false;
    }
  }
}
