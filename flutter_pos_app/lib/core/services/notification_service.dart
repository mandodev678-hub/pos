import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'pos_notifications';
  static const String _channelName = 'تنبيهات النظام';
  static const String _channelDescription = 'إشعارات نظام نقاط البيع';

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createAndroidChannel();
  }

  Future<void> _createAndroidChannel() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        ledColor: Color(0xFF1976D2),
      ),
    );
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> showOrderNotification({
    required int id,
    required String orderNumber,
    required String type,
  }) async {
    final title = type == 'order:new'
        ? 'طلب جديد'
        : type == 'order:updated'
            ? 'تم تحديث الطلب'
            : 'إشعار';
    final body = type == 'order:new'
        ? 'طلب #$orderNumber - يرجى المراجعة'
        : type == 'order:updated'
            ? 'طلب #$orderNumber - تم التحديث'
            : 'طلب #$orderNumber';
    await showNotification(id: id, title: title, body: body, payload: type);
  }

  Future<void> showNotificationFromEvent(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'إشعار جديد';
    final message = data['message'] as String? ?? '';
    final type = data['type'] as String? ?? 'general';
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await showNotification(id: id, title: title, body: message, payload: type);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigate to notifications screen when user taps the notification
    // Handled by the app's navigation logic
  }
}
