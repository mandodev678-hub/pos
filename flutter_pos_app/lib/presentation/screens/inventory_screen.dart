import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/models/user_model.dart';
import '../../data/models/warehouse_model.dart';
import '../../data/models/stock_item_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/transfers_repository.dart';
import '../../main.dart';
import 'inventory_barcode_flow.dart';

class InventoryScreen extends StatefulWidget {
  final UserModel? user;
  final int initialTabIndex;
  final Widget? drawer;
  const InventoryScreen({super.key, this.user, this.initialTabIndex = 0, this.drawer});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  final InventoryRepository _repo = InventoryRepository();
  final TransfersRepository _transfersRepo = TransfersRepository();
  late TabController _tabController;

  List<WarehouseModel> _warehouses = [];
  List<StockItemModel> _stockItems = [];
  List<StockAlertModel> _alerts = [];
  List<Map<String, dynamic>> _movements = [];
  List<Map<String, dynamic>> _transfers = [];

  String? _selectedWarehouseId;
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final initIdx = widget.initialTabIndex < (_isManager ? 5 : 3) ? widget.initialTabIndex : 0;
    _tabController = TabController(length: _isManager ? 5 : 3, vsync: this, initialIndex: initIdx)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isManager => widget.user?.role == 'admin' || widget.user?.role == 'manager';

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final futures = <Future>[
        _repo.getWarehouses(),
        _repo.getStock(warehouseId: _selectedWarehouseId, search: _searchQuery.isEmpty ? null : _searchQuery),
        _repo.getStockAlerts(),
      ];
      if (_isManager) {
        futures.addAll([
          _repo.getMovements(warehouseId: _selectedWarehouseId),
          _transfersRepo.getTransfers(warehouseId: _selectedWarehouseId),
        ]);
      }
      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _warehouses = results[0] as List<WarehouseModel>;
          _stockItems = results[1] as List<StockItemModel>;
          _alerts = results[2] as List<StockAlertModel>;
          if (_isManager && results.length > 3) {
            _movements = results[3] as List<Map<String, dynamic>>;
            _transfers = results[4] as List<Map<String, dynamic>>;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<StockItemModel> get _filteredStock => _searchQuery.isEmpty
      ? _stockItems
      : _stockItems.where((s) => s.nameAr.contains(_searchQuery)).toList();

  @override
  Widget build(BuildContext context) {
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
          title: Text('المخزون والمستودعات', style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          actions: [
            if (_tabController.index == 1)
              IconButton(
                onPressed: _showBarcodeScannerDialog,
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                tooltip: 'مسح الباركود',
              ),
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
              tabs: [
                Tab(icon: const Icon(Icons.warehouse, size: 18), text: 'المستودعات'),
                Tab(
                  icon: badges(_alerts.length, const Icon(Icons.inventory_2, size: 18)),
                  text: 'المخزون',
                ),
                Tab(icon: const Icon(Icons.warning_amber, size: 18), text: 'التنبيهات'),
                if (_isManager) ...[
                  Tab(icon: const Icon(Icons.swap_horiz, size: 18), text: 'التحويلات'),
                  Tab(icon: const Icon(Icons.history, size: 18), text: 'الحركات'),
                ],
              ],
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildWarehousesTab(),
                  _buildStockTab(),
                  _buildAlertsTab(),
                  if (_isManager) ...
                    [
                      _buildTransfersTab(),
                      _buildMovementsTab(),
                    ],
                ],
              ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget? _buildFAB() {
    if (_tabController.index == 1) {
      // Stock tab → adjust stock
      return FloatingActionButton.extended(
        onPressed: _showAdjustStockDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.tune, color: Colors.white),
        label: Text('تعديل مخزون', style: GoogleFonts.cairo(color: Colors.white)),
      );
    }
    if (_tabController.index == 3) {
      // Transfers tab → new transfer
      return FloatingActionButton.extended(
        onPressed: _showCreateTransferDialog,
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.swap_horiz, color: Colors.white),
        label: Text('تحويل جديد', style: GoogleFonts.cairo(color: Colors.white)),
      );
    }
    return FloatingActionButton(
      onPressed: _loadData,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.refresh, color: Colors.white),
    );
  }

  Widget badges(int count, Widget child) {
    if (count == 0) return child;
    return Badge(label: Text('$count'), child: child);
  }

  // ─── Warehouses Tab ──────────────────────────────────────────────────────
  Widget _buildWarehousesTab() {
    if (_warehouses.isEmpty) {
      return _emptyState(Icons.warehouse, 'لا توجد مستودعات مسجلة');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _warehouses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final w = _warehouses[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: w.isDefault
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warehouse,
                color: w.isDefault ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            title: Row(
              children: [
                Text(w.nameAr, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                if (w.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                    child: Text('رئيسي', style: GoogleFonts.cairo(color: Colors.white, fontSize: 10)),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (w.location != null)
                  Text(w.location!, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12)),
                if (w.stats != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statChip('${w.stats!.productCount} منتج', Icons.inventory, AppColors.primary),
                      const SizedBox(width: 8),
                      _statChip('${w.stats!.totalValue.toStringAsFixed(0)} ج.م', Icons.attach_money, AppColors.success),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: w.status == 'active'
                    ? AppColors.success.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                w.status == 'active' ? 'نشط' : 'غير نشط',
                style: GoogleFonts.cairo(
                  color: w.status == 'active' ? AppColors.success : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => _showWarehouseStock(w),
          ),
        );
      },
    );
  }

  void _showWarehouseStock(WarehouseModel w) {
    setState(() {
      _selectedWarehouseId = w.id;
      _tabController.animateTo(1);
    });
    _loadData();
  }

  Widget _statChip(String label, IconData icon, Color color) => Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label, style: GoogleFonts.cairo(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      );

  // ─── Stock Tab ───────────────────────────────────────────────────────────
  Widget _buildStockTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            onChanged: (v) {
              setState(() => _searchQuery = v);
              if (v.length >= 2 || v.isEmpty) _loadData();
            },
            decoration: const InputDecoration(
              hintText: 'بحث عن منتج في المخزون...',
              prefixIcon: Icon(Icons.search, color: AppColors.primary),
            ),
          ),
        ),
        if (_warehouses.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip('الكل', null),
                ..._warehouses.map((w) => _filterChip(w.nameAr, w.id)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        // Summary row
        if (_stockItems.isNotEmpty) ...[
          Builder(builder: (context) {
            final totalValue = _filteredStock.fold(0.0, (s, i) => s + (i.quantity * (i.avgCost ?? 0)));
            final totalQty = _filteredStock.fold(0.0, (s, i) => s + i.quantity);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${_filteredStock.length} أصناف (${totalQty.toStringAsFixed(0)} وحدة)',
                        style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        totalValue > 0
                            ? 'القيمة: ${totalValue.toStringAsFixed(0)} ج.م'
                            : 'المخزون متوفر',
                        style: GoogleFonts.cairo(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: _filteredStock.isEmpty
              ? _emptyState(Icons.inventory_2, 'لا توجد منتجات في المخزون')
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredStock.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = _filteredStock[index];
                    return Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showAdjustStockDialog(preselectedItem: s),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: s.isLowStock
                                      ? AppColors.error.withValues(alpha: 0.12)
                                      : AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      s.quantity.toStringAsFixed(0),
                                      style: GoogleFonts.cairo(
                                        color: s.isLowStock ? AppColors.error : AppColors.success,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      s.unit,
                                      style: GoogleFonts.cairo(
                                        color: s.isLowStock ? AppColors.error : AppColors.success,
                                        fontSize: 9,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.nameAr,
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (s.warehouseName != null) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              s.warehouseName!,
                                              style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 10),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        if (s.minQuantity != null)
                                          Text(
                                            'حد أدنى: ${s.minQuantity!.toStringAsFixed(0)}',
                                            style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (s.avgCost != null && s.avgCost! > 0)
                                    Text(
                                      '${s.avgCost!.toStringAsFixed(2)} ج.م',
                                      style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  if (s.isLowStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '⚠ منخفض',
                                        style: GoogleFonts.cairo(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? id) {
    final isSelected = _selectedWarehouseId == id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedWarehouseId = id);
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ─── Alerts Tab ──────────────────────────────────────────────────────────
  Widget _buildAlertsTab() {
    if (_alerts.isEmpty) {
      return _emptyState(Icons.check_circle_outline, 'لا توجد تنبيهات مخزون ✅');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final a = _alerts[index];
        final isOut = a.alertType == 'out_of_stock';
        return Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isOut ? AppColors.error : AppColors.warning).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isOut ? Icons.remove_circle_outline : Icons.warning_amber,
                color: isOut ? AppColors.error : AppColors.warning,
              ),
            ),
            title: Text(a.nameAr, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'المخزون: ${a.currentStock.toStringAsFixed(0)} | الحد الأدنى: ${a.minStock.toStringAsFixed(0)}',
              style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isOut ? AppColors.error : AppColors.warning).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isOut ? 'نفد' : 'منخفض',
                style: GoogleFonts.cairo(
                  color: isOut ? AppColors.error : AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Transfers Tab ───────────────────────────────────────────────────────
  Widget _buildTransfersTab() {
    if (_transfers.isEmpty) {
      return _emptyState(Icons.swap_horiz, 'لا توجد تحويلات بين المستودعات');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _transfers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final t = _transfers[index];
        final status = t['status'] ?? 'pending';
        final statusColors = {
          'completed': AppColors.success,
          'pending': AppColors.warning,
          'cancelled': AppColors.error,
          'confirmed': AppColors.primary,
        };
        final statusLabels = {
          'completed': 'مكتمل',
          'pending': 'معلق',
          'cancelled': 'ملغي',
          'confirmed': 'مؤكد',
        };
        final color = statusColors[status] ?? Colors.grey;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(Icons.swap_horiz, color: color),
            ),
            title: Text(
              '${t['fromWarehouse']?['name_ar'] ?? '—'} → ${t['toWarehouse']?['name_ar'] ?? '—'}',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              'بتاريخ: ${_formatDate(t['created_at'])}',
              style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabels[status] ?? status, style: GoogleFonts.cairo(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            onTap: () => _showTransferDetails(t),
          ),
        );
      },
    );
  }

  // ─── Movements Tab ───────────────────────────────────────────────────────
  Widget _buildMovementsTab() {
    if (_movements.isEmpty) {
      return _emptyState(Icons.history, 'لا توجد حركات مخزون مسجلة');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _movements.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final m = _movements[index];
        final qty = (m['quantity'] ?? m['quantity_change'] ?? 0).toString();
        final type = m['movement_type'] ?? m['source_type'] ?? '';
        final isIn = type.contains('in') || type.contains('purchase') || type.contains('add') || type.contains('return') || type.contains('adjustment') && (m['quantity_change'] ?? 0) > 0;

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isIn ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIn ? Icons.arrow_circle_down : Icons.arrow_circle_up,
              color: isIn ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          title: Text(
            m['Menu']?['name_ar'] ?? m['product_name'] ?? m['menu_id'] ?? '—',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          subtitle: Text(
            _movementTypeLabel(type),
            style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIn ? '+' : '-'}$qty',
                style: GoogleFonts.cairo(
                  color: isIn ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                _formatDate(m['created_at']),
                style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────
  Future<void> _showBarcodeScannerDialog() async {
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('مسح الباركود', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 320,
          height: 320,
          child: MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
              final normalizedBarcode = InventoryBarcodeFlow.normalizeBarcode(barcode);
              if (normalizedBarcode == null) return;
              await controller.stop();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _handleScannedBarcode(normalizedBarcode);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await controller.stop();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    await controller.dispose();
  }

  Future<void> _handleScannedBarcode(String barcode) async {
    final normalizedBarcode = InventoryBarcodeFlow.normalizeBarcode(barcode);
    if (normalizedBarcode == null) return;

    try {
      final products = await _repo.getInventoryProducts(search: normalizedBarcode, trackStockOnly: true);
      Map<String, dynamic>? product;
      try {
        product = products.firstWhere((p) => (p['barcode']?.toString() ?? '').toLowerCase() == normalizedBarcode.toLowerCase());
      } catch (_) {
        if (products.isNotEmpty) product = products.first;
      }

      if (product != null) {
        await _showBarcodeAdjustmentDialog(
          menuId: product['id'].toString(),
          productName: product['name_ar'] ?? product['name_en'] ?? 'منتج',
          barcode: normalizedBarcode,
        );
      } else {
        final created = await _repo.quickCreateProduct(
          nameAr: 'منتج $normalizedBarcode',
          nameEn: 'Item $normalizedBarcode',
          barcode: normalizedBarcode,
          itemType: 'raw_material',
          unitOfMeasure: 'piece',
          costPrice: 0,
          sellingPrice: 0,
          minStock: 0,
        );
        await _showBarcodeAdjustmentDialog(
          menuId: created['id'].toString(),
          productName: created['name_ar'] ?? created['name_en'] ?? 'منتج',
          barcode: normalizedBarcode,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _showBarcodeAdjustmentDialog({
    required String menuId,
    required String productName,
    required String barcode,
  }) async {
    if (_warehouses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب وجود مستودع واحد على الأقل')),
      );
      return;
    }

    final warehouseId = _selectedWarehouseId ?? _warehouses.first.id;
    final qtyCtrl = TextEditingController(text: '1');
    final reasonCtrl = TextEditingController(text: 'إضافة بالباركود');
    final costCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.add_circle, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(child: Text('إضافة مخزون بالباركود', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('المنتج: $productName\nالباركود: $barcode', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: warehouseId,
                decoration: InputDecoration(
                  labelText: 'المستودع',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: _warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.nameAr, style: GoogleFonts.cairo()))).toList(),
                onChanged: (v) => {},
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'الكمية *',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'تكلفة الوحدة (اختياري)',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixText: 'ج.م',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: 'السبب / الملاحظة',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final qty = double.tryParse(qtyCtrl.text) ?? 0;
              if (qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال كمية أكبر من الصفر')),
                );
                return;
              }
              final cost = costCtrl.text.isNotEmpty ? double.tryParse(costCtrl.text) : null;
              Navigator.pop(ctx);
              try {
                await _repo.adjustStock(
                  menuId: menuId,
                  warehouseId: warehouseId,
                  quantityChange: qty,
                  reason: reasonCtrl.text.isNotEmpty ? reasonCtrl.text : 'إضافة بالباركود',
                  unitCost: cost,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ تم إضافة المخزون بنجاح'), backgroundColor: AppColors.success),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text('تأكيد الإضافة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog({StockItemModel? preselectedItem}) {
    if (_warehouses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب وجود مستودع واحد على الأقل')),
      );
      return;
    }

    String? selectedMenuId = preselectedItem?.menuId;
    String? selectedWarehouseId = _selectedWarehouseId ?? _warehouses.first.id;
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    bool isAddition = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.tune, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('تعديل المخزون', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warehouse picker
                DropdownButtonFormField<String>(
                  initialValue: selectedWarehouseId,
                  decoration: InputDecoration(
                    labelText: 'المستودع',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _warehouses.map((w) => DropdownMenuItem(
                    value: w.id,
                    child: Text(w.nameAr, style: GoogleFonts.cairo()),
                  )).toList(),
                  onChanged: (v) => setStateDialog(() => selectedWarehouseId = v),
                ),
                const SizedBox(height: 12),
                // Product picker from stock
                if (preselectedItem != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📦 ${preselectedItem.nameAr}',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: selectedMenuId,
                    decoration: InputDecoration(
                      labelText: 'المنتج',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    isExpanded: true,
                    items: _stockItems.map((s) => DropdownMenuItem(
                      value: s.menuId,
                      child: Text(s.nameAr, style: GoogleFonts.cairo(), overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setStateDialog(() => selectedMenuId = v),
                  ),
                const SizedBox(height: 12),
                // Type toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setStateDialog(() => isAddition = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isAddition ? AppColors.success : Colors.grey.shade200,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                          ),
                          alignment: Alignment.center,
                          child: Text('➕ إضافة', style: GoogleFonts.cairo(color: isAddition ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setStateDialog(() => isAddition = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isAddition ? AppColors.error : Colors.grey.shade200,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                          ),
                          alignment: Alignment.center,
                          child: Text('➖ خصم', style: GoogleFonts.cairo(color: !isAddition ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'الكمية *',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(isAddition ? Icons.add : Icons.remove, color: isAddition ? AppColors.success : AppColors.error),
                  ),
                ),
                const SizedBox(height: 12),
                if (isAddition)
                  TextField(
                    controller: costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'تكلفة الوحدة (اختياري)',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      suffixText: 'ج.م',
                    ),
                  ),
                if (isAddition) const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    labelText: 'السبب / الملاحظة *',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.notes),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAddition ? AppColors.success : AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final menuIdToUse = preselectedItem?.menuId ?? selectedMenuId;
                if (menuIdToUse == null || qtyCtrl.text.isEmpty || reasonCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
                  );
                  return;
                }
                final qty = double.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) return;
                final change = isAddition ? qty : -qty;
                final cost = costCtrl.text.isNotEmpty ? double.tryParse(costCtrl.text) : null;
                Navigator.pop(ctx);
                try {
                  await _repo.adjustStock(
                    menuId: menuIdToUse,
                    warehouseId: selectedWarehouseId!,
                    quantityChange: change,
                    reason: reasonCtrl.text,
                    unitCost: cost,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ تم تعديل المخزون بنجاح'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: Text('تأكيد التعديل', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTransferDialog() {
    if (_warehouses.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب وجود مستودعين على الأقل للتحويل')),
      );
      return;
    }

    String fromWarehouseId = _warehouses[0].id;
    String toWarehouseId = _warehouses[1].id;
    final notesCtrl = TextEditingController();
    String? selectedMenuId;
    final qtyCtrl = TextEditingController();
    final List<Map<String, dynamic>> items = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.swap_horiz, color: Color(0xFF6C63FF)),
              const SizedBox(width: 8),
              Text('تحويل بين مستودعات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: fromWarehouseId,
                    decoration: InputDecoration(
                      labelText: 'من مستودع',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.nameAr, style: GoogleFonts.cairo()))).toList(),
                    onChanged: (v) => setS(() => fromWarehouseId = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: toWarehouseId,
                    decoration: InputDecoration(
                      labelText: 'إلى مستودع',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.nameAr, style: GoogleFonts.cairo()))).toList(),
                    onChanged: (v) => setS(() => toWarehouseId = v!),
                  ),
                  const SizedBox(height: 16),
                  // Add item row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedMenuId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'منتج',
                            labelStyle: GoogleFonts.cairo(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: _stockItems.map((s) => DropdownMenuItem(
                            value: s.menuId,
                            child: Text(s.nameAr, style: GoogleFonts.cairo(fontSize: 12), overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) => setS(() => selectedMenuId = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'كمية',
                            labelStyle: GoogleFonts.cairo(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (selectedMenuId == null || qtyCtrl.text.isEmpty) return;
                          final qty = double.tryParse(qtyCtrl.text) ?? 0;
                          if (qty <= 0) return;
                          final stock = _stockItems.firstWhere((s) => s.menuId == selectedMenuId, orElse: () => _stockItems.first);
                          setS(() {
                            items.add({'menu_id': selectedMenuId, 'quantity': qty, 'name': stock.nameAr});
                            selectedMenuId = null;
                            qtyCtrl.clear();
                          });
                        },
                        icon: const Icon(Icons.add_circle, color: AppColors.success, size: 28),
                      ),
                    ],
                  ),
                  // Items list
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (_, i) => ListTile(
                          dense: true,
                          title: Text(items[i]['name'] ?? '', style: GoogleFonts.cairo(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${items[i]['quantity']}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                              IconButton(
                                onPressed: () => setS(() => items.removeAt(i)),
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: items.isEmpty ? null : () async {
                if (fromWarehouseId == toWarehouseId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يجب أن يكون المستودعان مختلفين')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _transfersRepo.createTransfer(
                    fromWarehouseId: fromWarehouseId,
                    toWarehouseId: toWarehouseId,
                    items: items.map((i) => {'menu_id': i['menu_id'], 'quantity': i['quantity']}).toList(),
                    notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ تم إنشاء طلب التحويل بنجاح'), backgroundColor: AppColors.success),
                    );
                    _tabController.animateTo(3);
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: Text('إنشاء التحويل', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferDetails(Map<String, dynamic> t) {
    final status = t['status'] ?? 'pending';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تفاصيل التحويل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('من:', t['fromWarehouse']?['name_ar'] ?? '—'),
            _detailRow('إلى:', t['toWarehouse']?['name_ar'] ?? '—'),
            _detailRow('الحالة:', status),
            _detailRow('التاريخ:', _formatDate(t['created_at'])),
            const Divider(),
            Text('الأصناف:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ...((t['items'] as List? ?? []).map((item) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• ${item['Menu']?['name_ar'] ?? item['menu_id']}: ${item['quantity']}', style: GoogleFonts.cairo(fontSize: 13)),
            ))),
          ],
        ),
        actions: [
          if (status == 'pending') ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _transfersRepo.confirmTransfer(t['id']);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ تم تأكيد التحويل'), backgroundColor: AppColors.success),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.error));
                }
              },
              child: Text('تأكيد', style: GoogleFonts.cairo(color: AppColors.success, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _transfersRepo.cancelTransfer(t['id']);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إلغاء التحويل'), backgroundColor: Colors.orange),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.error));
                }
              },
              child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.error)),
            ),
          ],
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إغلاق', style: GoogleFonts.cairo())),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(label, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(width: 8),
        Text(value, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    ),
  );

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

  String _formatDate(dynamic date) {
    if (date == null) return '—';
    try {
      final d = DateTime.parse(date.toString()).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date.toString().substring(0, 10);
    }
  }

  String _movementTypeLabel(String type) {
    const labels = {
      'sale': 'مبيعات',
      'purchase': 'مشتريات',
      'adjustment': 'تعديل مخزون',
      'transfer_in': 'استلام تحويل',
      'transfer_out': 'إرسال تحويل',
      'return': 'مرتجع',
      'assembly_consume': 'استهلاك تصنيع',
      'assembly_produce': 'إنتاج تصنيع',
      'stock_issue': 'إذن صرف',
    };
    return labels[type] ?? type;
  }
}
