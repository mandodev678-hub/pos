import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../data/models/dashboard_stats_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import 'customers_screen.dart';
import 'inventory_screen.dart';
import 'login_screen.dart';
import 'pos_main_screen.dart';
import 'purchases_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'shift_screen.dart';
import 'tables_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String? userName;
  final UserModel? user;
  final Widget? drawer;
  const DashboardScreen({super.key, this.userName, this.user, this.drawer});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardRepository _repository = DashboardRepository();
  DashboardStatsModel? _stats;
  String? _storeName;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.fetchDashboardData(),
        _repository.fetchStoreName(),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as DashboardStatsModel;
          _storeName = results[1] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        drawer: _buildDrawer(context),
        body: _isLoading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildDashboard(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('جاري تحميل البيانات...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _error ?? 'حدث خطأ',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final stats = _stats!;
    final summary = stats.summary;
    final numberFormat = NumberFormat('#,##0.00', 'ar');

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          _buildHeader(stats),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stats.stockAlerts.isNotEmpty) ...[
                    _buildStockAlertBanner(stats.stockAlerts),
                    const SizedBox(height: 16),
                  ],
                  _buildQuickActions(context),
                  const SizedBox(height: 20),
                  _buildSectionTitle('ملخص المبيعات والتشغيل'),
                  const SizedBox(height: 12),
                  _buildSalesKpis(summary, numberFormat),
                  const SizedBox(height: 20),
                  _buildSectionTitle('الملخص المالي'),
                  const SizedBox(height: 12),
                  _buildFinancialKpis(stats.financial, numberFormat),
                  const SizedBox(height: 20),
                  _buildSectionTitle('توزيع المبيعات بالساعة'),
                  const SizedBox(height: 12),
                  _buildHourlyChart(stats.hourlyBreakdown),
                  const SizedBox(height: 20),
                  if (stats.topItems.isNotEmpty) ...[
                    _buildSectionTitle('الأصناف الأكثر مبيعاً'),
                    const SizedBox(height: 12),
                    _buildTopItems(stats.topItems),
                    const SizedBox(height: 20),
                  ],
                  if (stats.recentOrders.isNotEmpty) ...[
                    _buildSectionTitle('العمليات الأخيرة'),
                    const SizedBox(height: 12),
                    _buildRecentOrders(stats.recentOrders),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(DashboardStatsModel stats) {
    final timeStr = DateFormat('hh:mm a', 'ar').format(stats.lastUpdated);
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                const Spacer(),
                Text(
                  'آخر تحديث: $timeStr',
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً بك ${widget.userName ?? ''}',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _storeName ?? 'زمام POS',
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockAlertBanner(List<StockAlert> alerts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تنبيه مخزون (${alerts.length} أصناف منخفضة)',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE65100),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alerts.take(3).map((a) => '${a.name} (${a.currentStock} ${a.unit})').join(' • '),
                  style: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('عرض', style: GoogleFonts.cairo(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.point_of_sale_rounded, label: 'الكاشير', color: const Color(0xFF1A237E), onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PosMainScreen(user: widget.user!)));
      }),
      _QuickAction(icon: Icons.receipt_long_rounded, label: 'الطلبات', color: const Color(0xFF00897B), onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen(user: widget.user)));
      }),
      _QuickAction(icon: Icons.access_time_filled_rounded, label: 'الورديات', color: const Color(0xFF5C6BC0), onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftScreen()));
      }),
      _QuickAction(icon: Icons.table_restaurant_rounded, label: 'الطاولات', color: const Color(0xFFEF6C00), onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TablesScreen(onTableSelected: (_) {})));
      }),
      _QuickAction(icon: Icons.warehouse_rounded, label: 'المخزون', color: const Color(0xFF2E7D32), onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
      }),
      _QuickAction(icon: Icons.shopping_bag_rounded, label: 'المشتريات', color: const Color(0xFFAD1457), onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesScreen()));
      }),
      _QuickAction(icon: Icons.bar_chart_rounded, label: 'التقارير', color: const Color(0xFF6A1B9A), onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen()));
      }),
      _QuickAction(icon: Icons.people_alt_rounded, label: 'العملاء', color: const Color(0xFF0097A7), onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen()));
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: action.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: action.color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(action.icon, color: action.color, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  action.label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildSalesKpis(DailySummary summary, NumberFormat fmt) {
    final kpis = [
      _KpiData(
        label: 'إجمالي الطلبات',
        value: '${summary.totalOrders}',
        icon: Icons.shopping_cart_rounded,
        color: const Color(0xFF1A237E),
      ),
      _KpiData(
        label: 'قيد التنفيذ',
        value: '${summary.activeOrders}',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFEF6C00),
      ),
      _KpiData(
        label: 'مكتملة',
        value: '${summary.completedOrders}',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF2E7D32),
      ),
      _KpiData(
        label: 'إيراد اليوم',
        value: '${fmt.format(summary.totalSales)} ر.س',
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF6A1B9A),
      ),
    ];
    return _buildKpiGrid(kpis);
  }

  Widget _buildFinancialKpis(FinancialSummary financial, NumberFormat fmt) {
    final kpis = [
      _KpiData(
        label: 'المدفوعات',
        value: '${fmt.format(financial.totalPayments)} ر.س',
        icon: Icons.payments_rounded,
        color: const Color(0xFF2E7D32),
      ),
      _KpiData(
        label: 'المصروفات',
        value: '${fmt.format(financial.totalExpenses)} ر.س',
        icon: Icons.money_off_rounded,
        color: const Color(0xFFC62828),
      ),
      _KpiData(
        label: 'مصروفات اليوم',
        value: '${fmt.format(financial.todayExpenses)} ر.س',
        icon: Icons.receipt_rounded,
        color: const Color(0xFFE65100),
      ),
      _KpiData(
        label: 'المبالغ الآجلة',
        value: '${fmt.format(financial.totalCredit)} ر.س',
        icon: Icons.credit_score_rounded,
        color: const Color(0xFF0097A7),
      ),
    ];
    return _buildKpiGrid(kpis);
  }

  Widget _buildKpiGrid(List<_KpiData> kpis) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: kpi.color.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kpi.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(kpi.icon, color: kpi.color, size: 20),
              ),
              const Spacer(),
              Text(
                kpi.value,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                kpi.label,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHourlyChart(List<HourlyData> hourly) {
    if (hourly.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          'لا توجد بيانات مبيعات بعد',
          style: GoogleFonts.cairo(color: Colors.grey),
        ),
      );
    }

    final maxRevenue = hourly.map((h) => h.revenue).fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'الساعة',
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
              ),
              const Spacer(),
              Text(
                'الذروة: ${_peakHourLabel(hourly)}',
                style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF6A1B9A), fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                'المتوسط: ${_averageLabel(hourly)}',
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxRevenue > 0 ? maxRevenue / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: hourly.length > 12 ? 3 : 1,
                      getTitlesWidget: (value, meta) {
                        final h = value.toInt();
                        if (h >= 0 && h < 24) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$h',
                              style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: hourly.map((h) => FlSpot(h.hour.toDouble(), h.revenue)).toList(),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF1A237E),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final isPeak = spot.y == maxRevenue;
                        return FlDotCirclePainter(
                          radius: isPeak ? 5 : 3,
                          color: isPeak ? const Color(0xFFC62828) : const Color(0xFF1A237E),
                          strokeColor: Colors.white,
                          strokeWidth: 2,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A237E).withValues(alpha: 0.2),
                          const Color(0xFF1A237E).withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        return LineTooltipItem(
                          '${spot.x.toInt()}:00\n${NumberFormat('#,##0.00').format(spot.y)} ر.س',
                          GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _peakHourLabel(List<HourlyData> hourly) {
    if (hourly.isEmpty) return '--';
    final peak = hourly.reduce((a, b) => a.revenue > b.revenue ? a : b);
    return '${peak.hour}:00';
  }

  String _averageLabel(List<HourlyData> hourly) {
    if (hourly.isEmpty) return '0';
    final avg = hourly.map((h) => h.revenue).fold<double>(0, (a, b) => a + b) / hourly.length;
    return '${NumberFormat('#,##0').format(avg)} ر.س';
  }

  Widget _buildTopItems(List<TopItem> items) {
    final maxRevenue = items.isNotEmpty
        ? items.map((i) => i.revenue).fold<double>(0, (a, b) => a > b ? a : b)
        : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final progress = maxRevenue > 0 ? item.revenue / maxRevenue : 0.0;
          final colors = [
            const Color(0xFFFFD700),
            const Color(0xFFC0C0C0),
            const Color(0xFFCD7F32),
            const Color(0xFF1A237E),
            const Color(0xFF2E7D32),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors[index].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors[index],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${item.quantity} قطعة',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(colors[index]),
                  minHeight: 6,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecentOrders(List<RecentOrder> orders) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final order = orders[index];
          final timeStr = order.createdAt != null
              ? DateFormat('hh:mm a', 'ar').format(order.createdAt!)
              : '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _statusIcon(order.status),
                    color: _statusColor(order.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${order.orderNumber}',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _paymentStatusColor(order.paymentStatus).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.paymentStatusAr,
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: _paymentStatusColor(order.paymentStatus),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.customerName ?? 'عميل'} • ${order.paymentMethodAr}',
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${NumberFormat('#,##0.00').format(order.total)} ر.س',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    Text(
                      timeStr,
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return const Color(0xFF2E7D32);
      case 'cancelled': return const Color(0xFFC62828);
      case 'ready': return const Color(0xFF1565C0);
      case 'preparing': return const Color(0xFFEF6C00);
      default: return const Color(0xFF5C6BC0);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'ready': return Icons.restaurant_rounded;
      case 'preparing': return Icons.local_fire_department_rounded;
      default: return Icons.receipt_rounded;
    }
  }

  Color _paymentStatusColor(String ps) {
    switch (ps) {
      case 'paid': return const Color(0xFF2E7D32);
      case 'pending': return const Color(0xFFEF6C00);
      case 'refunded': return const Color(0xFFC62828);
      case 'partially_refunded': return const Color(0xFFE65100);
      default: return Colors.grey;
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.dashboard_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'لوحة التحكم',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.userName ?? '',
                    style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            _drawerItem(Icons.dashboard_rounded, 'لوحة التحكم', () => Navigator.pop(context)),
            _drawerItem(Icons.point_of_sale_rounded, 'نقطة البيع', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => PosMainScreen(user: widget.user!)));
            }),
            _drawerItem(Icons.table_restaurant_rounded, 'الطاولات', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => TablesScreen(onTableSelected: (_) {})));
            }),
            _drawerItem(Icons.access_time_filled_rounded, 'الورديات', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftScreen()));
            }),
            _drawerItem(Icons.warehouse_rounded, 'المخزون', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
            }),
            _drawerItem(Icons.shopping_bag_rounded, 'المشتريات', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesScreen()));
            }),
            _drawerItem(Icons.bar_chart_rounded, 'التقارير', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen()));
            }),
            _drawerItem(Icons.people_alt_rounded, 'العملاء', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen()));
            }),
            const Divider(),
            _drawerItem(Icons.settings_rounded, 'الإعدادات', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            _drawerItem(Icons.logout_rounded, 'تسجيل الخروج', () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A237E)),
      title: Text(label, style: GoogleFonts.cairo()),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiData({required this.label, required this.value, required this.icon, required this.color});
}
