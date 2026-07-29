class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String? message;
  final String? targetRole;
  final String? targetUserId;
  final String? entityType;
  final String? entityId;
  final String? actionUrl;
  final bool isRead;
  final String? icon;
  final String priority;
  final bool playSound;
  final String? branchId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    this.message,
    this.targetRole,
    this.targetUserId,
    this.entityType,
    this.entityId,
    this.actionUrl,
    this.isRead = false,
    this.icon,
    this.priority = 'normal',
    this.playSound = true,
    this.branchId,
    required this.createdAt,
    required this.updatedAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'],
      targetRole: json['target_role'],
      targetUserId: json['target_user_id']?.toString(),
      entityType: json['entity_type'],
      entityId: json['entity_id']?.toString(),
      actionUrl: json['action_url'],
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      icon: json['icon'],
      priority: json['priority'] ?? 'normal',
      playSound: json['play_sound'] ?? json['playSound'] ?? true,
      branchId: json['branch_id']?.toString(),
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? json['updatedAt'] ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'message': message,
    'target_role': targetRole,
    'target_user_id': targetUserId,
    'entity_type': entityType,
    'entity_id': entityId,
    'action_url': actionUrl,
    'is_read': isRead,
    'icon': icon,
    'priority': priority,
    'play_sound': playSound,
    'branch_id': branchId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'read_at': readAt?.toIso8601String(),
  };

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      message: message,
      targetRole: targetRole,
      targetUserId: targetUserId,
      entityType: entityType,
      entityId: entityId,
      actionUrl: actionUrl,
      isRead: isRead ?? this.isRead,
      icon: icon,
      priority: priority,
      playSound: playSound,
      branchId: branchId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
