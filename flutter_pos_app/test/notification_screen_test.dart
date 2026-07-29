import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pos_app/data/models/notification_model.dart';
import 'package:flutter_pos_app/data/repositories/notification_repository.dart';
import 'package:flutter_pos_app/presentation/providers/notification_provider.dart';
import 'package:flutter_pos_app/presentation/screens/notifications_screen.dart';

class MockNotificationRepository extends NotificationRepository {
  final Future<({List<NotificationModel> notifications, int unreadCount})> Function()? getNotificationsOverride;
  final Future<bool> Function(String)? markAsReadOverride;

  MockNotificationRepository({this.getNotificationsOverride, this.markAsReadOverride});

  @override
  Future<({List<NotificationModel> notifications, int unreadCount})> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    if (getNotificationsOverride != null) return getNotificationsOverride!();
    return (notifications: <NotificationModel>[], unreadCount: 0);
  }

  @override
  Future<bool> markAsRead(String id) async {
    if (markAsReadOverride != null) return markAsReadOverride!(id);
    return true;
  }
}

Widget _buildTestApp(NotificationProvider provider) {
  return MaterialApp(
    home: ChangeNotifierProvider.value(
      value: provider,
      child: const NotificationsScreen(),
    ),
  );
}

void main() {
  group('NotificationsScreen', () {
    testWidgets('should show empty state when no notifications', (tester) async {
      final provider = NotificationProvider(
        repository: MockNotificationRepository(
          getNotificationsOverride: () async => (notifications: <NotificationModel>[], unreadCount: 0),
        ),
      );

      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('لا توجد تنبيهات'), findsOneWidget);
    });

    testWidgets('should display notification list', (tester) async {
      final notifications = [
        NotificationModel(
          id: 'n1',
          type: 'order_new',
          title: 'طلب جديد',
          message: 'طلب #123',
          createdAt: DateTime(2026, 7, 29, 10, 0),
          updatedAt: DateTime(2026, 7, 29, 10, 0),
          isRead: false,
          priority: 'high',
        ),
        NotificationModel(
          id: 'n2',
          type: 'order_ready',
          title: 'الطلب جاهز',
          message: 'طلب #456 جاهز للتسليم',
          createdAt: DateTime(2026, 7, 29, 9, 0),
          updatedAt: DateTime(2026, 7, 29, 9, 0),
          isRead: true,
          priority: 'normal',
        ),
      ];

      final provider = NotificationProvider(
        repository: MockNotificationRepository(
          getNotificationsOverride: () async => (notifications: notifications, unreadCount: 1),
        ),
      );

      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('طلب جديد'), findsOneWidget);
      expect(find.text('الطلب جاهز'), findsOneWidget);
      expect(find.text('طلب #123'), findsOneWidget);
      expect(find.text('طلب #456 جاهز للتسليم'), findsOneWidget);
    });

    testWidgets('should show unread count in header summary', (tester) async {
      final notifications = [
        NotificationModel(
          id: 'n1',
          type: 'order_new',
          title: 'New',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          isRead: false,
        ),
      ];

      final provider = NotificationProvider(
        repository: MockNotificationRepository(
          getNotificationsOverride: () async => (notifications: notifications, unreadCount: 1),
        ),
      );

      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      // Should display summary with count
      expect(find.textContaining('غير مقروء'), findsOneWidget);
    });

    testWidgets('should show mark all as read button when unread exist', (tester) async {
      final notifications = [
        NotificationModel(
          id: 'n1',
          type: 'order_new',
          title: 'New',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          isRead: false,
        ),
      ];

      final provider = NotificationProvider(
        repository: MockNotificationRepository(
          getNotificationsOverride: () async => (notifications: notifications, unreadCount: 1),
          markAsReadOverride: (id) async => true,
        ),
      );

      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('تحديد الكل كمقروء'), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (tester) async {
      final completer = Completer<({List<NotificationModel> notifications, int unreadCount})>();
      final provider = NotificationProvider(
        repository: MockNotificationRepository(
          getNotificationsOverride: () => completer.future,
        ),
      );

      await tester.pumpWidget(_buildTestApp(provider));
      // Post-frame callback fires, starts fetchNotifications (which awaits completer.future)
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display notification with urgent priority badge', (tester) async {
      final notifications = [
        NotificationModel(
          id: 'n1',
          type: 'order_cancelled',
          title: 'تم الإلغاء',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          isRead: false,
          priority: 'urgent',
        ),
      ];

      final provider = NotificationProvider(
        repository: MockNotificationRepository(
          getNotificationsOverride: () async => (notifications: notifications, unreadCount: 1),
        ),
      );

      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('عاجل'), findsOneWidget);
    });
  });
}
