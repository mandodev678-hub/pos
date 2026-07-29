import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider({NotificationRepository? repository}) : _repository = repository ?? NotificationRepository();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  StreamSubscription? _socketSubscription;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnread => _unreadCount > 0;

  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _repository.getNotifications(unreadOnly: unreadOnly);
      _notifications = result.notifications;
      _unreadCount = result.unreadCount;
    } catch (_) {
      _notifications = [];
      _unreadCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final success = await _repository.markAsRead(id);
    if (success) {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true, readAt: DateTime.now());
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    final success = await _repository.markAllAsRead();
    if (success) {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true, readAt: DateTime.now());
      }
      _unreadCount = 0;
      notifyListeners();
    }
  }

  void addNotificationFromSocket(Map<String, dynamic> data) {
    final notification = NotificationModel.fromJson(data);
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();
  }

  Future<void> cleanup() async {
    final success = await _repository.cleanup();
    if (success) {
      await fetchNotifications();
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }
}
