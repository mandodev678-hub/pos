import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/user_model.dart';
import '../../main.dart';
import '../../core/network/socket_client.dart';
import '../providers/cart_provider.dart';
import '../providers/kds_provider.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'login_screen.dart';
import 'pos_main_screen.dart';
import 'purchases_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'shift_screen.dart';
import 'tables_screen.dart';

class HomeShell extends StatefulWidget {
  final UserModel user;
  const HomeShell({super.key, required this.user});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  int _reportsInitialTab = 0;
  int _inventoryInitialTab = 0;
  int _purchasesInitialTab = 0;

  @override
  void initState() {
    super.initState();
    final socket = SocketClient();
    socket.initSocket(
      branchId: widget.user.branchId,
      role: widget.user.role,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<KdsProvider>().init(socket);
        socket.onOrderUpdated = (data) {
          final status = data['status'] as String?;
          if (status == 'ready') {
            if (mounted) {
              final orderNumber = data['order_number'] ?? data['orderNumber'] ?? '';
              final tableNumber = data['table_number'] ?? data['tableNumber'];
              final msg = tableNumber != null
                  ? 'الطلب #$orderNumber جاهز للاستلام (طاولة $tableNumber) 🍽️'
                  : 'الطلب #$orderNumber جاهز للاستلام ✅';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg, style: GoogleFonts.cairo()),
                  backgroundColor: const Color(0xFF2E7D32),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'عرض',
                    textColor: Colors.white,
                    onPressed: () {
                      context.read<KdsProvider>().acknowledgeReadyOrders();
                    },
                  ),
                ),
              );
            }
          }
        };
      }
    });
  }

  @override
  void dispose() {
    SocketClient().disconnect();
    super.dispose();
  }

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, label: 'الرئيسية'),
    _NavItem(icon: Icons.point_of_sale_outlined, selectedIcon: Icons.point_of_sale_rounded, label: 'الكاشير'),
    _NavItem(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart_rounded, label: 'التقارير'),
    _NavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2_rounded, label: 'المخزون'),
    _NavItem(icon: Icons.shopping_bag_outlined, selectedIcon: Icons.shopping_bag_rounded, label: 'المشتريات'),
    _NavItem(icon: Icons.people_outline_rounded, selectedIcon: Icons.people_alt_rounded, label: 'العملاء'),
  ];

  void _navigateToModule(int screenIndex, {int subTab = 0}) {
    setState(() {
      _currentIndex = screenIndex;
      if (screenIndex == 2) _reportsInitialTab = subTab;
      if (screenIndex == 3) _inventoryInitialTab = subTab;
      if (screenIndex == 4) _purchasesInitialTab = subTab;
    });
  }

  Widget _buildScreen(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(userName: widget.user.nameAr, user: widget.user, drawer: _buildDetailedDrawer(context));
      case 1:
        return PosMainScreen(user: widget.user, embeddedMode: true, drawer: _buildDetailedDrawer(context));
      case 2:
        return ReportsScreen(
          key: ValueKey('reports-$_reportsInitialTab'),
          user: widget.user,
          initialTabIndex: _reportsInitialTab,
          drawer: _buildDetailedDrawer(context),
        );
      case 3:
        return InventoryScreen(
          key: ValueKey('inventory-$_inventoryInitialTab'),
          user: widget.user,
          initialTabIndex: _inventoryInitialTab,
          drawer: _buildDetailedDrawer(context),
        );
      case 4:
        return PurchasesScreen(
          key: ValueKey('purchases-$_purchasesInitialTab'),
          user: widget.user,
          initialTabIndex: _purchasesInitialTab,
          drawer: _buildDetailedDrawer(context),
        );
      case 5:
        return CustomersScreen(drawer: _buildDetailedDrawer(context));
      case 6:
        return SettingsScreen(user: widget.user, drawer: _buildDetailedDrawer(context));
      default:
        return DashboardScreen(userName: widget.user.nameAr, user: widget.user, drawer: _buildDetailedDrawer(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final kds = context.watch<KdsProvider>();
    // Hide bottom nav bar when Settings screen (index 6) is open
    final showBottomNav = _currentIndex < 6;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: _buildDetailedDrawer(context),
        body: _buildScreen(context),
        bottomNavigationBar: showBottomNav
            ? NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                backgroundColor: Colors.white,
                indicatorColor: AppColors.primary.withValues(alpha: 0.12),
                shadowColor: Colors.black12,
                elevation: 4,
                destinations: _navItems.map((item) {
                  final isCart = item.label == 'الكاشير';
                  final cartBadge = isCart && cart.items.isNotEmpty;
                  final kdsBadge = isCart && kds.readyCount > 0;
                  Widget iconWidget = Icon(item.icon);
                  if (cartBadge) {
                    iconWidget = Badge(
                      label: Text('${cart.totalQuantity}'),
                      child: iconWidget,
                    );
                  } else if (kdsBadge) {
                    iconWidget = Badge(
                      label: Text('${kds.readyCount}'),
                      backgroundColor: const Color(0xFF2E7D32),
                      child: iconWidget,
                    );
                  }
                  Widget selectedIconWidget = Icon(item.selectedIcon, color: AppColors.primary);
                  if (cartBadge) {
                    selectedIconWidget = Badge(
                      label: Text('${cart.totalQuantity}'),
                      child: selectedIconWidget,
                    );
                  } else if (kdsBadge) {
                    selectedIconWidget = Badge(
                      label: Text('${kds.readyCount}'),
                      backgroundColor: const Color(0xFF2E7D32),
                      child: selectedIconWidget,
                    );
                  }
                  return NavigationDestination(
                    icon: iconWidget,
                    selectedIcon: selectedIconWidget,
                    label: item.label,
                  );
                }).toList(),
              )
            : null,
      ),
    );
  }

  // ─── Enterprise Detailed Drawer Menu ───────────────────────────────────────
  Widget _buildDetailedDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: 310,
      child: Column(
        children: [
          // Drawer Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(
                        widget.user.nameAr.isNotEmpty ? widget.user.nameAr[0] : 'م',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.nameAr,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _roleLabel(widget.user.role),
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'زمام POS • الفرع الرئيسي',
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Modules Tree Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 0. Dashboard
                _drawerSubItem(
                  icon: Icons.dashboard_rounded,
                  label: 'لوحة التحكم',
                  isSelected: _currentIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToModule(0);
                  },
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                // 1. POS Module
                _buildExpansionModule(
                  title: 'نقطة البيع والصالة',
                  icon: Icons.point_of_sale_rounded,
                  color: AppColors.primary,
                  isInitiallyExpanded: false,
                  children: [
                    _drawerSubItem(
                      icon: Icons.shopping_cart_outlined,
                      label: 'شاشة الكاشير والطلب',
                      isSelected: _currentIndex == 1,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(1);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.table_restaurant_outlined,
                      label: 'إدارة الطاولات والصالة',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TablesScreen(
                              onTableSelected: (n) => context.read<CartProvider>().setTableNumber(n),
                            ),
                          ),
                        );
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.access_time_filled_outlined,
                      label: 'إدارة الوردية والصندوق',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShiftScreen()),
                        );
                      },
                    ),
                  ],
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                // 2. Reports Module
                _buildExpansionModule(
                  title: 'التقارير والإحصائيات',
                  icon: Icons.bar_chart_rounded,
                  color: Colors.purple,
                  isInitiallyExpanded: false,
                  children: [
                    _drawerSubItem(
                      icon: Icons.dashboard_outlined,
                      label: 'لوحة مبيعات اليوم',
                      isSelected: _currentIndex == 2 && _reportsInitialTab == 0,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(2, subTab: 0);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.badge_outlined,
                      label: 'تقرير أداء الموظفين',
                      isSelected: _currentIndex == 2 && _reportsInitialTab == 1,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(2, subTab: 1);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.local_fire_department_outlined,
                      label: 'الأصناف الأكثر مبيعاً',
                      isSelected: _currentIndex == 2 && _reportsInitialTab == 2,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(2, subTab: 2);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.date_range_outlined,
                      label: 'تقارير الفترة الزمنية',
                      isSelected: _currentIndex == 2 && _reportsInitialTab == 3,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(2, subTab: 3);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.account_balance_outlined,
                      label: 'المطابقة المالية اليومية',
                      isSelected: _currentIndex == 2 && _reportsInitialTab == 4,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(2, subTab: 4);
                      },
                    ),
                  ],
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                // 3. Inventory Module
                _buildExpansionModule(
                  title: 'المخزون والمستودعات',
                  icon: Icons.warehouse_rounded,
                  color: AppColors.secondary,
                  isInitiallyExpanded: _currentIndex == 3,
                  children: [
                    _drawerSubItem(
                      icon: Icons.warehouse_outlined,
                      label: 'دليل المستودعات',
                      isSelected: _currentIndex == 3 && _inventoryInitialTab == 0,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(3, subTab: 0);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'المخزون والأصناف',
                      isSelected: _currentIndex == 3 && _inventoryInitialTab == 1,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(3, subTab: 1);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.warning_amber_rounded,
                      label: 'تنبيهات الأصناف والحد الأدنى',
                      isSelected: _currentIndex == 3 && _inventoryInitialTab == 2,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(3, subTab: 2);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.swap_horiz_rounded,
                      label: 'التحويلات بين المستودعات',
                      isSelected: _currentIndex == 3 && _inventoryInitialTab == 3,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(3, subTab: 3);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.history_toggle_off_rounded,
                      label: 'سجل حرَكات المخزون',
                      isSelected: _currentIndex == 3 && _inventoryInitialTab == 4,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(3, subTab: 4);
                      },
                    ),
                  ],
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                // 4. Purchases Module
                _buildExpansionModule(
                  title: 'المشتريات والموردين',
                  icon: Icons.shopping_bag_rounded,
                  color: AppColors.warning,
                  isInitiallyExpanded: _currentIndex == 4,
                  children: [
                    _drawerSubItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'فواتير الشراء',
                      isSelected: _currentIndex == 4 && _purchasesInitialTab == 0,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(4, subTab: 0);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.assignment_outlined,
                      label: 'أوامر الشراء',
                      isSelected: _currentIndex == 4 && _purchasesInitialTab == 1,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(4, subTab: 1);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.people_outline_rounded,
                      label: 'دليل وحسابات الموردين',
                      isSelected: _currentIndex == 4 && _purchasesInitialTab == 2,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(4, subTab: 2);
                      },
                    ),
                  ],
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                // 5. Customers Module
                _buildExpansionModule(
                  title: 'إدارة العملاء',
                  icon: Icons.people_alt_rounded,
                  color: Colors.teal,
                  isInitiallyExpanded: _currentIndex == 5,
                  children: [
                    _drawerSubItem(
                      icon: Icons.contacts_outlined,
                      label: 'دليل العملاء وحساباتهم',
                      isSelected: _currentIndex == 5,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(5);
                      },
                    ),
                  ],
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                // 6. System Settings Module
                _buildExpansionModule(
                  title: 'إعدادات النظام والمنشأة',
                  icon: Icons.settings_rounded,
                  color: Colors.blueGrey,
                  isInitiallyExpanded: _currentIndex == 6,
                  children: [
                    _drawerSubItem(
                      icon: Icons.storefront_outlined,
                      label: 'بيانات المنشأة والمتجر',
                      isSelected: _currentIndex == 6,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(6);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.tune_outlined,
                      label: 'سير العمل والتشغيل',
                      isSelected: _currentIndex == 6,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(6);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'إعدادات الفاتورة والطباعة',
                      isSelected: _currentIndex == 6,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(6);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.notifications_active_outlined,
                      label: 'التنبيهات والنظام والعملة',
                      isSelected: _currentIndex == 6,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(6);
                      },
                    ),
                    _drawerSubItem(
                      icon: Icons.badge_outlined,
                      label: 'سياسات التأخير والجزاءات',
                      isSelected: _currentIndex == 6,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToModule(6);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Drawer Footer - Logout Button
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'تسجيل الخروج',
                style: GoogleFonts.cairo(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    title: Row(
                      children: [
                        const Icon(Icons.logout, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text('تسجيل الخروج', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: Text('هل أنت متأكد من تسجيل الخروج من النظام؟', style: GoogleFonts.cairo()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('إلغاء', style: GoogleFonts.cairo()),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        child: Text(
                          'تأكيد الخروج',
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Expansion tile container helper
  Widget _buildExpansionModule({
    required String title,
    required IconData icon,
    required Color color,
    required bool isInitiallyExpanded,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isInitiallyExpanded,
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        childrenPadding: const EdgeInsets.only(right: 16, bottom: 4),
        children: children,
      ),
    );
  }

  // Drawer subitem helper
  Widget _drawerSubItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        icon,
        size: 18,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'مدير النظام';
      case 'manager':
        return 'مدير فرع';
      case 'supervisor':
        return 'مشرف';
      case 'accountant':
        return 'محاسب';
      case 'cashier':
        return 'كاشير';
      default:
        return role;
    }
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
