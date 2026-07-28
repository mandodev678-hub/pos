import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/order_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/orders_repository.dart';
import '../../main.dart';

class ReportsScreen extends StatefulWidget {
  final UserModel? user;
  final int initialTabIndex;
  final Widget? drawer;
  const ReportsScreen({super.key, this.user, this.initialTabIndex = 0, this.drawer});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final OrdersRepository _repo = OrdersRepository();
  late TabController _tabController;

  Map<String, dynamic> _dailySummary = {};
  List<OrderModel> _recentOrders = [];
  List<Map<String, dynamic>> _bestSellers = [];
  List<Map<String, dynamic>> _staffPerformance = [];
  Map<String, dynamic> _reconciliation = {};
  Map<String, dynamic> _rangeReport = {};

  bool _loading = true;
  DateTimeRange? _selectedDateRange;

  bool get _isManager =>
      widget.user?.role == 'admin' ||
      widget.user?.role == 'manager' ||
      widget.user?.role == 'supervisor' ||
      widget.user?.role == 'accountant';

  @override
  void initState() {
    super.initState();
    final initIdx = widget.initialTabIndex < 5 ? widget.initialTabIndex : 0;
    _tabController = TabController(length: 5, vsync: this, initialIndex: initIdx)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    if (_isManager) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!_isManager) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getDailySummary(),
        _repo.getOrders(limit: 30),
        _repo.getBestSellers(),
        _repo.getStaffPerformance(),
        _repo.getDailyReconciliation(),
      ]);

      if (mounted) {
        setState(() {
          _dailySummary = results[0] as Map<String, dynamic>;
          _recentOrders = results[1] as List<OrderModel>;
          _bestSellers = results[2] as List<Map<String, dynamic>>;
          _staffPerformance = results[3] as List<Map<String, dynamic>>;
          _reconciliation = results[4] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل التقرير: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchRangeReport() async {
    if (_selectedDateRange == null) return;
    final startStr = _selectedDateRange!.start.toISOStringDate();
    final endStr = _selectedDateRange!.end.toISOStringDate();
    try {
      final res = await _repo.getRangeReport(startDate: startStr, endDate: endStr);
      if (mounted) setState(() => _rangeReport = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل جلب تقرير الفترة: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isManager) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          drawer: widget.drawer,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                tooltip: 'القائمة الرئيسية',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Text('التقارير والإحصائيات', style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('هذه الشاشة للمديرين والمشرفين فقط',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('يرجى تسجيل الدخول بحساب مدير لمشاهدة الإحصائيات',
                    style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: widget.drawer,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
              tooltip: 'القائمة الرئيسية',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Text('التقارير والإحصائيات الشاملة', style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'تحديث',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kTextTabBarHeight),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'لوحة الإحصائيات'),
                Tab(icon: Icon(Icons.badge_rounded, size: 18), text: 'أداء الموظفين'),
                Tab(icon: Icon(Icons.local_fire_department_rounded, size: 18), text: 'الأكثر مبيعاً'),
                Tab(icon: Icon(Icons.date_range_rounded, size: 18), text: 'تقرير الفترة'),
                Tab(icon: Icon(Icons.account_balance_rounded, size: 18), text: 'المطابقة المالية'),
              ],
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildStaffTab(),
                  _buildBestSellersTab(),
                  _buildRangeTab(),
                  _buildReconciliationTab(),
                ],
              ),
      ),
    );
  }

  // ─── 1. Dashboard Tab ──────────────────────────────────────────────────────
  Widget _buildDashboardTab() {
    final summary = _dailySummary['summary'] as Map<String, dynamic>? ?? _dailySummary;
    final totalSales = double.tryParse('${summary['totalSales'] ?? summary['total_sales'] ?? 0}') ?? 0.0;
    final netRevenue = double.tryParse('${summary['netRevenue'] ?? totalSales}') ?? totalSales;
    final totalTax = double.tryParse('${summary['totalTax'] ?? 0}') ?? 0.0;
    final totalOrders = int.tryParse('${summary['totalOrders'] ?? summary['total_orders'] ?? 0}') ?? 0;
    final cancelledOrders = int.tryParse('${summary['cancelledOrders'] ?? 0}') ?? 0;
    final avgOrder = double.tryParse('${summary['averageOrderValue'] ?? 0}') ?? 0.0;
    final refundAmount = double.tryParse('${summary['refundAmount'] ?? 0}') ?? 0.0;

    final cashSales = double.tryParse('${summary['cashSales'] ?? 0}') ?? 0.0;
    final cardSales = double.tryParse('${summary['cardSales'] ?? 0}') ?? 0.0;
    final onlineSales = double.tryParse('${summary['onlineSales'] ?? 0}') ?? 0.0;

    final hourlyList = (_dailySummary['hourlyBreakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Grid Row 1
          Row(
            children: [
              _kpiCard('مبيعات اليوم الإجمالية', '${totalSales.toStringAsFixed(2)} ج.م', Icons.payments_rounded, AppColors.primary),
              const SizedBox(width: 12),
              _kpiCard('صافي الإيراد', '${netRevenue.toStringAsFixed(2)} ج.م', Icons.account_balance_wallet_rounded, AppColors.success),
            ],
          ),
          const SizedBox(height: 12),

          // KPI Grid Row 2
          Row(
            children: [
              _kpiCard('إجمالي الطلبات', '$totalOrders طلب', Icons.receipt_long_rounded, const Color(0xFF6C63FF)),
              const SizedBox(width: 12),
              _kpiCard('متوسط الفاتورة', '${avgOrder.toStringAsFixed(2)} ج.م', Icons.trending_up_rounded, AppColors.warning),
            ],
          ),
          const SizedBox(height: 12),

          // KPI Grid Row 3
          Row(
            children: [
              _kpiCard('الضرائب المجمعة', '${totalTax.toStringAsFixed(2)} ج.م', Icons.request_quote_rounded, Colors.teal),
              const SizedBox(width: 12),
              _kpiCard('المرتجعات ($cancelledOrders ملغي)', '${refundAmount.toStringAsFixed(2)} ج.م', Icons.assignment_return_rounded, AppColors.error),
            ],
          ),
          const SizedBox(height: 20),

          // Payment Methods Breakdown Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pie_chart_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('توزيع طرق الدفع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 24),
                  _paymentProgressBar('كاش / نقدي', cashSales, totalSales, AppColors.success),
                  const SizedBox(height: 12),
                  _paymentProgressBar('شبكة / بطاقة', cardSales, totalSales, AppColors.primary),
                  const SizedBox(height: 12),
                  _paymentProgressBar('أونلاين / دفع إلكتروني', onlineSales, totalSales, const Color(0xFF6C63FF)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hourly Breakdown if available
          if (hourlyList.isNotEmpty) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text('المبيعات حسب الساعات (اليوم)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: hourlyList.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final h = hourlyList[i];
                          final hour = h['hour'];
                          final rev = double.tryParse('${h['revenue'] ?? 0}') ?? 0.0;
                          final ords = h['orders'] ?? 0;
                          return Container(
                            width: 70,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${hour.toString().padLeft(2, '0')}:00', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${rev.toStringAsFixed(0)}ج', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                Text('$ords طلب', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recent Orders Header & List
          if (_recentOrders.isNotEmpty) ...[
            Text('أحدث الطلبات المنفذة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ..._recentOrders.take(5).map((o) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(_orderTypeIcon(o.orderType), color: AppColors.primary, size: 18),
                    ),
                    title: Text('#${o.orderNumber} - ${o.orderTypeLabel}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('${o.cashierName ?? "كاشير"} • ${o.paymentMethod}', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
                    trailing: Text('${o.total.toStringAsFixed(2)} ج.م', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.success)),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ─── 2. Staff Performance Tab ──────────────────────────────────────────────
  Widget _buildStaffTab() {
    if (_staffPerformance.isEmpty) {
      return _emptyState(Icons.badge_rounded, 'لا توجد بيانات موظفين مسجلة للفترة الحالية');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _staffPerformance.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final st = _staffPerformance[index];
        final rank = index + 1;
        final name = st['name'] ?? 'موظف';
        final sales = double.tryParse('${st['totalSales'] ?? 0}') ?? 0.0;
        final count = int.tryParse('${st['ordersCount'] ?? 0}') ?? 0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: rank == 1
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.1),
              radius: 22,
              child: Text(
                '#$rank',
                style: GoogleFonts.cairo(
                  color: rank == 1 ? AppColors.warning : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('عدد الفواتير: $count طلب', style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${sales.toStringAsFixed(2)} ج.م',
                  style: GoogleFonts.cairo(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'إجمالي المبيعات',
                  style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 3. Best Sellers Tab ───────────────────────────────────────────────────
  Widget _buildBestSellersTab() {
    if (_bestSellers.isEmpty) {
      return _emptyState(Icons.local_fire_department_rounded, 'لا توجد أصناف مباعة حالياً');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _bestSellers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final b = _bestSellers[index];
        final rank = index + 1;
        final name = b['name_ar'] ?? b['nameAr'] ?? b['item_name'] ?? 'منتج';
        final qty = (b['total_quantity'] ?? b['quantity'] ?? 0).toInt();
        final rev = double.tryParse('${b['total_revenue'] ?? b['revenue'] ?? 0}') ?? 0.0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? [AppColors.warning, Colors.grey.shade400, const Color(0xFFCD7F32)][rank - 1].withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '#$rank',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3
                      ? [AppColors.warning, Colors.grey.shade700, const Color(0xFFCD7F32)][rank - 1]
                      : AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('تم بيع: $qty قطعة', style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12)),
            trailing: Text(
              '${rev.toStringAsFixed(2)} ج.م',
              style: GoogleFonts.cairo(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  // ─── 4. Date Range Tab ─────────────────────────────────────────────────────
  Widget _buildRangeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('حدد الفترة الزمنية لاستخراج التقرير المالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.date_range, color: Colors.white),
                    label: Text(
                      _selectedDateRange == null
                          ? 'اختيار الفترة الزمنية'
                          : '${_selectedDateRange!.start.toISOStringDate()}  ←  ${_selectedDateRange!.end.toISOStringDate()}',
                      style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now(),
                        initialDateRange: _selectedDateRange ??
                            DateTimeRange(
                              start: DateTime.now().subtract(const Duration(days: 7)),
                              end: DateTime.now(),
                            ),
                      );
                      if (picked != null) {
                        setState(() => _selectedDateRange = picked);
                        _fetchRangeReport();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_rangeReport.isNotEmpty) ...[
            Row(
              children: [
                _kpiCard(
                  'إجمالي المبيعات بالفترة',
                  '${double.tryParse("${_rangeReport['totalSales'] ?? 0}")?.toStringAsFixed(2)} ج.م',
                  Icons.monetization_on,
                  AppColors.primary,
                ),
                const SizedBox(width: 12),
                _kpiCard(
                  'إجمالي عدد الطلبات',
                  '${_rangeReport['totalOrders'] ?? 0} طلب',
                  Icons.receipt,
                  AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text('متوسط المبيعات اليومية بالفترة', style: GoogleFonts.cairo(fontSize: 13)),
                trailing: Text(
                  '${double.tryParse("${_rangeReport['averageDaily'] ?? 0}")?.toStringAsFixed(2)} ج.م',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('التفاصيل اليومية للفترة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...((_rangeReport['dailyBreakdown'] as List? ?? []).map((d) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    title: Text('${d['date']}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    subtitle: Text('${d['orders']} طلبات', style: GoogleFonts.cairo(fontSize: 11)),
                    trailing: Text(
                      '${double.tryParse("${d['revenue'] ?? 0}")?.toStringAsFixed(2)} ج.م',
                      style: GoogleFonts.cairo(color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ),
                ))),
          ],
        ],
      ),
    );
  }

  // ─── 5. Reconciliation Tab ─────────────────────────────────────────────────
  Widget _buildReconciliationTab() {
    final pos = _reconciliation['pos'] as Map<String, dynamic>? ?? {};
    final gateway = _reconciliation['gateway'] as Map<String, dynamic>? ?? {};
    final gl = _reconciliation['gl'] as Map<String, dynamic>? ?? {};
    final variances = _reconciliation['variances'] as Map<String, dynamic>? ?? {};

    if (_reconciliation.isEmpty) {
      return _emptyState(Icons.account_balance_rounded, 'لا توجد بيانات مطابقة مالية متاحة اليوم');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مطابقة اليوم بين POS وبوابة الدفع والدفتر العام (GL)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),

          // POS summary card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.point_of_sale, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('سجلات نظام POS', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(),
                  _rowDetail('إجمالي مبيعات POS:', '${pos['gross_sales'] ?? "0.00"} ج.م'),
                  _rowDetail('المبالغ الإلكتـرونية / شبكـة:', '${pos['non_cash_total'] ?? "0.00"} ج.م'),
                  _rowDetail('المبالغ النقديــة (كاش):', '${pos['cash'] ?? "0.00"} ج.م'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Gateway summary card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.credit_card, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 8),
                      Text('سجلات بوابة الدفع (Gateway)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(),
                  _rowDetail('إجمالي المقبوضات المؤكدة:', '${gateway['webhook_confirmed_total'] ?? "0.00"} ج.م'),
                  _rowDetail('عدد المعاملات المؤكدة:', '${gateway['confirmations_count'] ?? 0} عملية'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // GL summary card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.book, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text('سجلات الأستاذ العام (GL Bank Debit)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(),
                  _rowDetail('قيود البنك الـمرحّلة:', '${gl['bank_debit_from_order_entries'] ?? "0.00"} ج.م'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Variances card
          Card(
            color: AppColors.primary.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.primary)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الفروقات واختلافات المطابقة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  _rowDetail('البوابة vs الـ POS (شبكة):', '${variances['gateway_vs_pos_non_cash'] ?? "0.00"} ج.م'),
                  _rowDetail('الأستاذ العام vs الـ POS (شبكة):', '${variances['gl_vs_pos_non_cash'] ?? "0.00"} ج.م'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _paymentProgressBar(String label, double amount, double total, Color color) {
    final pct = total > 0 ? (amount / total) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${amount.toStringAsFixed(2)} ج.م (${(pct * 100).toStringAsFixed(0)}%)',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct.toDouble(),
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _rowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFBDBDBD)),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  IconData _orderTypeIcon(String type) {
    switch (type) {
      case 'delivery':
        return Icons.delivery_dining;
      case 'takeaway':
        return Icons.takeout_dining;
      default:
        return Icons.table_restaurant;
    }
  }
}

extension DateTimeFormatHelper on DateTime {
  String toISOStringDate() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
}
