import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../providers/notification_provider.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';
import 'shift_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final Widget? drawer;
  const NotificationsScreen({super.key, this.drawer});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _navigateFromNotification(BuildContext context, dynamic notification) {
    final entityType = notification.entityType as String?;

    switch (entityType) {
      case 'order':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
      case 'stock':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryScreen()),
        );
      case 'shift':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShiftScreen()),
        );
      case 'system':
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('التنبيهات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          actions: [
            if (provider.hasUnread)
              TextButton.icon(
                onPressed: () => provider.markAllAsRead(),
                icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
                label: Text(
                  'تحديد الكل كمقروء',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                ),
              ),
            PopupMenuButton<String>(
              iconColor: Colors.white,
              onSelected: (v) {
                if (v == 'refresh') provider.fetchNotifications();
                if (v == 'cleanup') provider.cleanup();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'refresh', child: Text('تحديث')),
                const PopupMenuItem(value: 'cleanup', child: Text('حذف القديم (30 يوم)')),
              ],
            ),
          ],
        ),
        drawer: widget.drawer,
        body: _buildBody(provider, notifications),
      ),
    );
  }

  Widget _buildBody(NotificationProvider provider, List<dynamic> notifications) {
    if (provider.isLoading && notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'لا توجد تنبيهات',
              style: GoogleFonts.cairo(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.fetchNotifications(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: notifications.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '${notifications.length} تنبيه • ${provider.unreadCount} غير مقروء',
                style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
              ),
            );
          }
          final notification = notifications[index - 1];
          return _NotificationCard(
            notification: notification,
            onTap: () {
              provider.markAsRead(notification.id);
              _navigateFromNotification(context, notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    final icon = _typeIcon(notification.type);
    final color = _typeColor(notification.type, notification.priority);

    return Card(
      elevation: isRead ? 0 : 2,
      color: isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRead
            ? BorderSide.none
            : BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.message != null && notification.message!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        notification.message!,
                        style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _priorityBadge(notification.priority),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(notification.createdAt),
                          style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    Color bg;
    Color fg;
    String label;
    switch (priority) {
      case 'urgent':
        bg = AppColors.error.withValues(alpha: 0.1);
        fg = AppColors.error;
        label = 'عاجل';
      case 'high':
        bg = AppColors.warning.withValues(alpha: 0.1);
        fg = AppColors.warning;
        label = 'مهم';
      case 'low':
        bg = Colors.grey.withValues(alpha: 0.1);
        fg = Colors.grey;
        label = 'منخفض';
      default:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'order_new':
      case 'order_pending':
      case 'order_approved':
        return Icons.shopping_cart_checkout_rounded;
      case 'order_preparing':
        return Icons.restaurant_rounded;
      case 'order_ready':
        return Icons.check_circle_outline_rounded;
      case 'order_completed':
        return Icons.task_alt_rounded;
      case 'order_cancelled':
        return Icons.cancel_outlined;
      case 'low_stock':
        return Icons.inventory_2_outlined;
      case 'shift_alert':
        return Icons.access_time_filled_rounded;
      case 'system':
        return Icons.settings_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type, String priority) {
    if (priority == 'urgent' || priority == 'high') {
      if (type == 'order_cancelled') return AppColors.error;
      if (type == 'low_stock') return AppColors.warning;
      return AppColors.primary;
    }
    return AppColors.textSecondary;
  }
}
