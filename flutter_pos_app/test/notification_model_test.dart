import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pos_app/data/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('fromJson should parse all fields correctly', () {
      final json = {
        'id': 'notif-1',
        'type': 'order_new',
        'title': 'طلب جديد',
        'message': 'طلب #123 بقيمة 150 ج.م',
        'target_role': 'chef',
        'target_user_id': null,
        'entity_type': 'order',
        'entity_id': 'order-123',
        'action_url': '/kitchen',
        'is_read': false,
        'icon': '🛒',
        'priority': 'high',
        'play_sound': true,
        'branch_id': 'branch-1',
        'created_at': '2026-07-29T10:30:00.000Z',
        'updated_at': '2026-07-29T10:30:00.000Z',
        'read_at': null,
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 'notif-1');
      expect(model.type, 'order_new');
      expect(model.title, 'طلب جديد');
      expect(model.message, 'طلب #123 بقيمة 150 ج.م');
      expect(model.targetRole, 'chef');
      expect(model.targetUserId, null);
      expect(model.entityType, 'order');
      expect(model.entityId, 'order-123');
      expect(model.actionUrl, '/kitchen');
      expect(model.isRead, false);
      expect(model.icon, '🛒');
      expect(model.priority, 'high');
      expect(model.playSound, true);
      expect(model.branchId, 'branch-1');
      expect(model.createdAt, DateTime.utc(2026, 7, 29, 10, 30));
      expect(model.readAt, null);
    });

    test('fromJson should handle is_read alias (camelCase)', () {
      final json = {
        'id': 'n1',
        'type': 'system',
        'title': 'Test',
        'isRead': true,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      };
      final model = NotificationModel.fromJson(json);
      expect(model.isRead, true);
    });

    test('fromJson should handle missing optional fields gracefully', () {
      final json = {
        'id': 'n1',
        'type': 'system',
        'title': 'Test',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      };
      final model = NotificationModel.fromJson(json);
      expect(model.message, null);
      expect(model.targetRole, null);
      expect(model.targetUserId, null);
      expect(model.entityType, null);
      expect(model.icon, null);
      expect(model.priority, 'normal');
      expect(model.playSound, true);
      expect(model.branchId, null);
      expect(model.readAt, null);
      expect(model.isRead, false);
    });

    test('fromJson should handle null createdAt gracefully', () {
      final json = {
        'id': 'n1',
        'type': 'test',
        'title': 'Test',
        'created_at': null,
        'updated_at': null,
      };
      final model = NotificationModel.fromJson(json);
      expect(model.createdAt, isA<DateTime>());
      expect(model.updatedAt, isA<DateTime>());
    });

    test('copyWith should update isRead and readAt', () {
      final original = NotificationModel(
        id: 'n1',
        type: 'order_new',
        title: 'Test',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        isRead: false,
      );

      final readTime = DateTime(2026, 7, 29, 12, 0);
      final updated = original.copyWith(isRead: true, readAt: readTime);

      expect(updated.isRead, true);
      expect(updated.readAt, readTime);
      expect(updated.id, original.id);
      expect(updated.title, original.title);
    });

    test('copyWith should keep original values when no args given', () {
      final original = NotificationModel(
        id: 'n1',
        type: 'order_new',
        title: 'Test',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        isRead: false,
      );

      final updated = original.copyWith();
      expect(updated.isRead, false);
      expect(updated.readAt, null);
      expect(updated.id, 'n1');
    });

    test('toJson should produce valid JSON map', () {
      final model = NotificationModel(
        id: 'n1',
        type: 'order_ready',
        title: 'جاهز',
        message: 'الطلب جاهز',
        targetRole: 'cashier',
        entityType: 'order',
        entityId: 'o1',
        isRead: false,
        icon: '🔔',
        priority: 'high',
        playSound: true,
        branchId: 'b1',
        createdAt: DateTime(2026, 7, 29),
        updatedAt: DateTime(2026, 7, 29),
      );

      final json = model.toJson();

      expect(json['id'], 'n1');
      expect(json['type'], 'order_ready');
      expect(json['title'], 'جاهز');
      expect(json['message'], 'الطلب جاهز');
      expect(json['target_role'], 'cashier');
      expect(json['is_read'], false);
      expect(json['priority'], 'high');
    });
  });
}
