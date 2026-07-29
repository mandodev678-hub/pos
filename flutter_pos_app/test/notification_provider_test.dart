import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pos_app/data/models/notification_model.dart';
import 'package:flutter_pos_app/data/repositories/notification_repository.dart';
import 'package:flutter_pos_app/presentation/providers/notification_provider.dart';

class MockNotificationRepository extends NotificationRepository {
  final Future<({List<NotificationModel> notifications, int unreadCount})> Function()? getNotificationsOverride;
  final Future<bool> Function(String)? markAsReadOverride;
  final Future<bool> Function()? markAllAsReadOverride;
  final Future<bool> Function()? cleanupOverride;

  MockNotificationRepository({
    this.getNotificationsOverride,
    this.markAsReadOverride,
    this.markAllAsReadOverride,
    this.cleanupOverride,
  });

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

  @override
  Future<bool> markAllAsRead() async {
    if (markAllAsReadOverride != null) return markAllAsReadOverride!();
    return true;
  }

  @override
  Future<bool> cleanup() async {
    if (cleanupOverride != null) return cleanupOverride!();
    return true;
  }
}

NotificationModel _sampleNotif({String id = 'n1', bool isRead = false}) {
  return NotificationModel(
    id: id,
    type: 'order_new',
    title: 'طلب جديد',
    message: 'طلب #123',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    isRead: isRead,
  );
}

void main() {
  group('NotificationProvider', () {
    test('initial state should have empty list and zero unread', () {
      final provider = NotificationProvider(repository: MockNotificationRepository());
      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);
      expect(provider.hasUnread, false);
      expect(provider.isLoading, false);
    });

    test('fetchNotifications should populate list and unread count', () async {
      final mockNotifs = [_sampleNotif(id: 'n1', isRead: false), _sampleNotif(id: 'n2', isRead: true)];
      final provider = NotificationProvider(
        repository: MockNotificationRepository(
          getNotificationsOverride: () async => (notifications: mockNotifs, unreadCount: 1),
        ),
      );

      await provider.fetchNotifications();

      expect(provider.notifications.length, 2);
      expect(provider.unreadCount, 1);
      expect(provider.hasUnread, true);
    });

    test('markAsRead should update notification locally', () async {
      final notif = _sampleNotif(id: 'n1', isRead: false);
      final provider = NotificationProvider(
        repository: MockNotificationRepository(
          getNotificationsOverride: () async => (notifications: [notif], unreadCount: 1),
          markAsReadOverride: (id) async => true,
        ),
      );

      await provider.fetchNotifications();
      expect(provider.notifications.first.isRead, false);
      expect(provider.unreadCount, 1);

      await provider.markAsRead('n1');

      expect(provider.notifications.first.isRead, true);
      expect(provider.unreadCount, 0);
      expect(provider.hasUnread, false);
    });

    test('markAllAsRead should mark all as read locally', () async {
      final provider = NotificationProvider(
        repository: MockNotificationRepository(
          getNotificationsOverride: () async => (
            notifications: [
              _sampleNotif(id: 'n1', isRead: false),
              _sampleNotif(id: 'n2', isRead: false),
              _sampleNotif(id: 'n3', isRead: true),
            ],
            unreadCount: 2,
          ),
          markAllAsReadOverride: () async => true,
        ),
      );

      await provider.fetchNotifications();
      expect(provider.unreadCount, 2);

      await provider.markAllAsRead();

      expect(provider.notifications.every((n) => n.isRead), isTrue);
      expect(provider.unreadCount, 0);
    });

    test('addNotificationFromSocket should prepend notification', () async {
      final provider = NotificationProvider(repository: MockNotificationRepository());
      final data = {
        'id': 'socket-n1',
        'type': 'order_ready',
        'title': 'جاهز!',
        'message': 'الطلب #456 جاهز',
        'is_read': false,
        'created_at': '2026-07-29T10:00:00.000Z',
        'updated_at': '2026-07-29T10:00:00.000Z',
      };

      provider.addNotificationFromSocket(data);

      expect(provider.notifications.length, 1);
      expect(provider.notifications.first.id, 'socket-n1');
      expect(provider.notifications.first.title, 'جاهز!');
      expect(provider.unreadCount, 1);
    });

    test('addNotificationFromSocket should not increment unread for read notifications', () async {
      final provider = NotificationProvider(repository: MockNotificationRepository());
      final data = {
        'id': 'socket-n2',
        'type': 'system',
        'title': 'Info',
        'is_read': true,
        'created_at': '2026-07-29T10:00:00.000Z',
        'updated_at': '2026-07-29T10:00:00.000Z',
      };

      provider.addNotificationFromSocket(data);

      expect(provider.unreadCount, 0);
    });

    test('fetchNotifications should handle error gracefully', () async {
      final provider = NotificationProvider(
        repository: MockNotificationRepository(
          getNotificationsOverride: () => throw Exception('Network error'),
        ),
      );

      await provider.fetchNotifications();

      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);
    });

    test('markAsRead should handle API failure gracefully', () async {
      final provider = NotificationProvider(
        repository: MockNotificationRepository(
          getNotificationsOverride: () async => (notifications: [_sampleNotif(isRead: false)], unreadCount: 1),
          markAsReadOverride: (id) async => false,
        ),
      );

      await provider.fetchNotifications();
      expect(provider.unreadCount, 1);

      await provider.markAsRead('n1');

      expect(provider.notifications.first.isRead, false);
      expect(provider.unreadCount, 1);
    });
  });
}
