import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/purchase_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/purchases_repository.dart';
import '../../main.dart';

class PurchasesScreen extends StatefulWidget {
  final UserModel? user;
  final int initialTabIndex;
  final Widget? drawer;
  const PurchasesScreen({super.key, this.user, this.initialTabIndex = 0, this.drawer});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen>
    with SingleTickerProviderStateMixin {
  final PurchasesRepository _repo = PurchasesRepository();
  final InventoryRepository _invRepo = InventoryRepository();
  late TabController _tabController;

  List<PurchaseModel> _purchases = [];
  List<SupplierModel> _suppliers = [];
  List<Map<String, dynamic>> _purchaseOrders = [];
  bool _loading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    final initIdx = widget.initialTabIndex < 3 ? widget.initialTabIndex : 0;
    _tabController = TabController(length: 3, vsync: this, initialIndex: initIdx)
      ..addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isManager => widget.user?.role == 'admin' || widget.user?.role == 'manager';

  Future<void> _loadData() async {
    if (!_isManager) return; // cashier cannot access purchases
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getPurchases(status: _statusFilter == 'all' ? null : _statusFilter),
        _repo.getSuppliers(),
        _repo.getPurchaseOrders(),
      ]);
      if (mounted) {
        setState(() {
          _purchases = results[0] as List<PurchaseModel>;
          _suppliers = results[1] as List<SupplierModel>;
          _purchaseOrders = results[2] as List<Map<String, dynamic>>;
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
            automaticallyImplyLeading: false,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                tooltip: 'القائمة الرئيسية',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Text('المشتريات والموردين', style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('هذه الشاشة للمديرين فقط', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('يرجى تسجيل الدخول بحساب مدير أو أدمن', style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary)),
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
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
              tooltip: 'القائمة الرئيسية',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Text('المشتريات والموردين', style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Colors.white),
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
              tabs: const [
                Tab(icon: Icon(Icons.receipt_long), text: 'فواتير الشراء'),
                Tab(icon: Icon(Icons.assignment), text: 'أوامر الشراء'),
                Tab(icon: Icon(Icons.people), text: 'الموردين'),
              ],
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPurchasesTab(),
                  _buildPurchaseOrdersTab(),
                  _buildSuppliersTab(),
                ],
              ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget _buildFAB() {
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        onPressed: _showCreatePurchaseDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('فاتورة جديدة', style: GoogleFonts.cairo(color: Colors.white)),
      );
    }
    if (_tabController.index == 1) {
      return FloatingActionButton.extended(
        onPressed: _showCreatePurchaseOrderDialog,
        backgroundColor: const Color(0xFF7C4DFF),
        icon: const Icon(Icons.assignment_add, color: Colors.white),
        label: Text('أمر شراء جديد', style: GoogleFonts.cairo(color: Colors.white)),
      );
    }
    if (_tabController.index == 2) {
      return FloatingActionButton.extended(
        onPressed: _showCreateSupplierDialog,
        backgroundColor: const Color(0xFF00897B),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text('مورد جديد', style: GoogleFonts.cairo(color: Colors.white)),
      );
    }
    return FloatingActionButton(
      onPressed: _loadData,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.refresh, color: Colors.white),
    );
  }

  // ─── Purchases Tab ────────────────────────────────────────────────────────
  Widget _buildPurchasesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _summaryCard('إجمالي الفواتير', '${_purchases.length}', Icons.receipt, AppColors.primary),
              const SizedBox(width: 12),
              _summaryCard(
                'إجمالي المبلغ',
                '${_purchases.fold(0.0, (s, p) => s + p.totalAmount).toStringAsFixed(0)} ج.م',
                Icons.attach_money,
                AppColors.success,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _filterChip('الكل', 'all'),
              _filterChip('معلق', 'pending'),
              _filterChip('مدفوع جزئياً', 'partial'),
              _filterChip('مدفوع', 'paid'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _purchases.isEmpty
              ? _emptyState(Icons.receipt_long, 'لا توجد فواتير شراء بعد')
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _purchases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = _purchases[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showPurchaseDetails(p),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p.invoiceNumber ?? 'فاتورة #${p.id.substring(0, 8)}',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  _statusBadge(p.status, p.statusLabel),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    p.supplierName ?? 'مورد غير محدد',
                                    style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                  const Spacer(),
                                  if (p.createdAt != null)
                                    Text(
                                      '${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year}',
                                      style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _amountInfo('الإجمالي', p.totalAmount, AppColors.textPrimary),
                                  _amountInfo('المدفوع', p.paidAmount, AppColors.success),
                                  _amountInfo('المتبقي', p.remainingAmount, AppColors.error),
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

  Widget _amountInfo(String label, double amount, Color color) => Column(
        children: [
          Text(label, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11)),
          Text('${amount.toStringAsFixed(2)} ج.م',
              style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      );

  void _showPurchaseDetails(PurchaseModel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (_, scroll) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scroll,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      p.invoiceNumber ?? 'فاتورة #${p.id.substring(0, 8)}',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const Divider(),
                if (p.items.isEmpty)
                  Center(child: Text('لا توجد تفاصيل', style: GoogleFonts.cairo(color: AppColors.textSecondary)))
                else
                  ...p.items.map((item) => ListTile(
                        title: Text(item.menuItemName ?? 'منتج', style: GoogleFonts.cairo(fontSize: 13)),
                        trailing: Text(
                          '${item.quantity.toStringAsFixed(0)} × ${item.unitPrice.toStringAsFixed(2)} = ${item.total.toStringAsFixed(2)}',
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )),
                const Divider(),
                ListTile(
                  title: Text('الإجمالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  trailing: Text('${p.totalAmount.toStringAsFixed(2)} ج.م', style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Purchase Orders Tab ──────────────────────────────────────────────────
  Widget _buildPurchaseOrdersTab() {
    return Column(
      children: [
        // Summary
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _summaryCard('إجمالي الأوامر', '${_purchaseOrders.length}', Icons.assignment, const Color(0xFF7C4DFF)),
              const SizedBox(width: 12),
              _summaryCard(
                'مجموع القيمة',
                '${_purchaseOrders.fold(0.0, (s, o) => s + ((o['total_amount'] as num?)?.toDouble() ?? 0)).toStringAsFixed(0)} ج.م',
                Icons.monetization_on,
                AppColors.success,
              ),
            ],
          ),
        ),
        Expanded(
          child: _purchaseOrders.isEmpty
              ? _emptyState(Icons.assignment, 'لا توجد أوامر شراء')
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _purchaseOrders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final o = _purchaseOrders[index];
                    final status = o['status'] ?? 'draft';
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showPurchaseOrderActions(o),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.assignment, color: Color(0xFF7C4DFF), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      o['po_number'] ?? 'PO-${(o['id'] ?? '').toString().substring(0, 8)}',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  _poBadge(status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    o['Supplier']?['name_ar'] ?? o['supplier_name'] ?? '—',
                                    style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${((o['total_amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} ج.م',
                                    style: GoogleFonts.cairo(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              if (o['expected_date'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'تاريخ التسليم: ${_formatDate(o['expected_date'])}',
                                  style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
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

  Widget _poBadge(String status) {
    final data = {
      'draft': (Colors.grey, 'مسودة'),
      'confirmed': (AppColors.primary, 'مؤكد'),
      'partial': (AppColors.warning, 'جزئي'),
      'received': (AppColors.success, 'مستلم'),
      'cancelled': (AppColors.error, 'ملغي'),
    };
    final (color, label) = data[status] ?? (Colors.grey, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  void _showPurchaseOrderActions(Map<String, dynamic> o) {
    final status = o['status'] ?? 'draft';
    final id = o['id']?.toString() ?? '';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                o['po_number'] ?? 'أمر شراء',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                o['Supplier']?['name_ar'] ?? '—',
                style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 13),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppColors.success, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'الإجمالي: ${((o['total_amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} ج.م',
                    style: GoogleFonts.cairo(color: AppColors.success, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Actions based on status
              if (status == 'draft')
                _actionButton(
                  icon: Icons.check_circle,
                  label: 'تأكيد أمر الشراء',
                  color: AppColors.primary,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _doAction(() => _repo.confirmPurchaseOrder(id), 'تم تأكيد أمر الشراء');
                  },
                ),
              if (status == 'confirmed')
                _actionButton(
                  icon: Icons.local_shipping,
                  label: 'تسجيل استلام البضاعة',
                  color: AppColors.success,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReceiveDialog(o);
                  },
                ),
              if (status != 'received' && status != 'cancelled')
                _actionButton(
                  icon: Icons.cancel,
                  label: 'إلغاء أمر الشراء',
                  color: AppColors.error,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _doAction(() => _repo.cancelPurchaseOrder(id), 'تم إلغاء أمر الشراء');
                  },
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('إغلاق', style: GoogleFonts.cairo()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  void _showReceiveDialog(Map<String, dynamic> po) {
    final items = (po['items'] as List? ?? []);
    final invoiceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final qtyControllers = {for (var item in items) item['id']?.toString() ?? '': TextEditingController(text: '${item['quantity_ordered'] ?? 0}')};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.local_shipping, color: AppColors.success),
            const SizedBox(width: 8),
            Text('استلام البضاعة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: invoiceCtrl,
                decoration: InputDecoration(
                  labelText: 'رقم فاتورة المورد (اختياري)',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Text('لا توجد بنود في هذا الأمر', style: GoogleFonts.cairo(color: AppColors.textSecondary))
              else ...[
                Text('الكميات المستلمة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...items.map((item) {
                  final itemId = item['id']?.toString() ?? '';
                  final name = item['Menu']?['name_ar'] ?? 'منتج';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(name, style: GoogleFonts.cairo(fontSize: 13))),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: qtyControllers[itemId],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'ملاحظات',
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
              Navigator.pop(ctx);
              final receiveItems = items.map((item) {
                final itemId = item['id']?.toString() ?? '';
                return {
                  'purchase_order_item_id': itemId,
                  'quantity_received': double.tryParse(qtyControllers[itemId]?.text ?? '0') ?? 0,
                };
              }).toList();
              await _doAction(
                () => _repo.receivePurchaseOrder(
                  po['id'],
                  items: receiveItems,
                  invoiceNumber: invoiceCtrl.text.isNotEmpty ? invoiceCtrl.text : null,
                  notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                ),
                'تم تسجيل الاستلام بنجاح وتحديث المخزون',
              );
            },
            child: Text('تأكيد الاستلام', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _doAction(Future<dynamic> Function() action, String successMsg) async {
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ $successMsg'), backgroundColor: AppColors.success),
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
  }

  // ─── Suppliers Tab ────────────────────────────────────────────────────────
  Widget _buildSuppliersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _summaryCard('إجمالي الموردين', '${_suppliers.length}', Icons.people, const Color(0xFF00897B)),
              const SizedBox(width: 12),
              _summaryCard(
                'إجمالي الديون',
                '${_suppliers.fold(0.0, (s, sup) => s + (sup.balance > 0 ? sup.balance : 0)).toStringAsFixed(0)} ج.م',
                Icons.account_balance_wallet,
                AppColors.error,
              ),
            ],
          ),
        ),
        Expanded(
          child: _suppliers.isEmpty
              ? _emptyState(Icons.people, 'لا يوجد موردين مسجلين')
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _suppliers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final s = _suppliers[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          radius: 24,
                          child: Text(
                            s.nameAr.isNotEmpty ? s.nameAr[0] : 'م',
                            style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        title: Text(s.nameAr, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (s.phone != null)
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 12, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(s.phone!, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            if (s.balance != 0)
                              Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'الرصيد: ${s.balance.toStringAsFixed(2)} ج.م',
                                    style: GoogleFonts.cairo(
                                      color: s.balance > 0 ? AppColors.error : AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (action) => _handleSupplierAction(action, s),
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 16), const SizedBox(width: 8), Text('تعديل', style: GoogleFonts.cairo())])),
                            PopupMenuItem(value: 'pay', child: Row(children: [const Icon(Icons.payment, size: 16, color: AppColors.success), const SizedBox(width: 8), Text('تسجيل دفعة', style: GoogleFonts.cairo())])),
                            PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 16, color: AppColors.error), const SizedBox(width: 8), Text('إلغاء تفعيل', style: GoogleFonts.cairo(color: AppColors.error))])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _handleSupplierAction(String action, SupplierModel s) {
    switch (action) {
      case 'edit':
        _showEditSupplierDialog(s);
        break;
      case 'pay':
        _showAddPaymentDialog(s);
        break;
      case 'delete':
        _confirmDeleteSupplier(s);
        break;
    }
  }

  void _confirmDeleteSupplier(SupplierModel s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إلغاء تفعيل المورد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من إلغاء تفعيل "${s.nameAr}"؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await _doAction(() => _repo.deleteSupplier(s.id), 'تم إلغاء تفعيل المورد');
            },
            child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Create/Edit Dialogs ──────────────────────────────────────────────────
  void _showCreatePurchaseDialog() {
    if (_suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة مورد واحد على الأقل أولاً')),
      );
      return;
    }

    String? selectedSupplierId = _suppliers.first.id;
    String? selectedWarehouseId;
    final invoiceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final List<Map<String, dynamic>> items = [];
    List<Map<String, dynamic>> products = [];
    List<dynamic> warehouses = [];
    String? selectedProductId;
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // Load products and warehouses once
          if (products.isEmpty && warehouses.isEmpty) {
            _invRepo.getInventoryProducts().then((p) => setS(() => products = p));
            _invRepo.getWarehouses().then((w) {
              setS(() {
                warehouses = w;
                selectedWarehouseId = w.isNotEmpty ? w.first.id : null;
              });
            });
          }
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.receipt, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('فاتورة شراء جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedSupplierId,
                      decoration: InputDecoration(labelText: 'المورد', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      items: _suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nameAr, style: GoogleFonts.cairo()))).toList(),
                      onChanged: (v) => setS(() => selectedSupplierId = v),
                    ),
                    const SizedBox(height: 12),
                    if (warehouses.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedWarehouseId,
                        decoration: InputDecoration(labelText: 'المستودع', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        items: warehouses.map((w) => DropdownMenuItem(value: w.id as String, child: Text(w.nameAr as String, style: GoogleFonts.cairo()))).toList(),
                        onChanged: (v) => setS(() => selectedWarehouseId = v),
                      ),
                    if (warehouses.isNotEmpty) const SizedBox(height: 12),
                    TextField(
                      controller: invoiceCtrl,
                      decoration: InputDecoration(labelText: 'رقم الفاتورة (اختياري)', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                    const SizedBox(height: 16),
                    Text('إضافة أصناف:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (products.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedProductId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'منتج',
                                labelStyle: GoogleFonts.cairo(fontSize: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              items: products.map((p) => DropdownMenuItem(
                                value: p['id']?.toString(),
                                child: Text(p['name_ar'] ?? '', style: GoogleFonts.cairo(fontSize: 12), overflow: TextOverflow.ellipsis),
                              )).toList(),
                              onChanged: (v) => setS(() {
                                selectedProductId = v;
                                final prod = products.firstWhere((p) => p['id'] == v, orElse: () => {});
                                if (prod['cost_price'] != null) costCtrl.text = '${prod['cost_price']}';
                              }),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: qtyCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: 'كمية', labelStyle: GoogleFonts.cairo(fontSize: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: costCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: 'تكلفة', labelStyle: GoogleFonts.cairo(fontSize: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (selectedProductId == null || qtyCtrl.text.isEmpty) return;
                              final prod = products.firstWhere((p) => p['id'] == selectedProductId, orElse: () => {});
                              setS(() {
                                items.add({
                                  'menu_id': selectedProductId,
                                  'name': prod['name_ar'] ?? '',
                                  'quantity': double.tryParse(qtyCtrl.text) ?? 1,
                                  'unit_cost': double.tryParse(costCtrl.text) ?? 0,
                                });
                                selectedProductId = null;
                                qtyCtrl.clear();
                                costCtrl.clear();
                              });
                            },
                            icon: const Icon(Icons.add_circle, color: AppColors.success, size: 28),
                          ),
                        ],
                      ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (_, i) => ListTile(
                            dense: true,
                            title: Text('${items[i]['name']}', style: GoogleFonts.cairo(fontSize: 12)),
                            subtitle: Text('${items[i]['quantity']} × ${items[i]['unit_cost']} ج.م', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
                            trailing: IconButton(
                              onPressed: () => setS(() => items.removeAt(i)),
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 18),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'الإجمالي: ${items.fold(0.0, (s, i) => s + (i['quantity'] * i['unit_cost'])).toStringAsFixed(2)} ج.م',
                              style: GoogleFonts.cairo(color: AppColors.success, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(labelText: 'ملاحظات', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: items.isEmpty || selectedSupplierId == null ? null : () async {
                  Navigator.pop(ctx);
                  await _doAction(
                    () => _repo.createPurchase(
                      supplierId: selectedSupplierId!,
                      warehouseId: selectedWarehouseId ?? '',
                      items: items.map((i) => {'menu_id': i['menu_id'], 'quantity': i['quantity'], 'unit_cost': i['unit_cost']}).toList(),
                      invoiceNumber: invoiceCtrl.text.isNotEmpty ? invoiceCtrl.text : null,
                      notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                    ),
                    'تم إنشاء فاتورة الشراء وتحديث المخزون',
                  );
                },
                child: Text('حفظ الفاتورة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreatePurchaseOrderDialog() {
    if (_suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة مورد واحد على الأقل أولاً')),
      );
      return;
    }

    String? selectedSupplierId = _suppliers.first.id;
    String? selectedWarehouseId;
    final notesCtrl = TextEditingController();
    String? expectedDate;
    List<Map<String, dynamic>> products = [];
    List<dynamic> warehouses = [];
    String? selectedProductId;
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final List<Map<String, dynamic>> items = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          if (products.isEmpty && warehouses.isEmpty) {
            _invRepo.getInventoryProducts().then((p) => setS(() => products = p));
            _invRepo.getWarehouses().then((w) => setS(() {
              warehouses = w;
              if (w.isNotEmpty) selectedWarehouseId = w.first.id;
            }));
          }
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.assignment_add, color: Color(0xFF7C4DFF)),
                const SizedBox(width: 8),
                Text('أمر شراء جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedSupplierId,
                      decoration: InputDecoration(labelText: 'المورد *', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      items: _suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nameAr, style: GoogleFonts.cairo()))).toList(),
                      onChanged: (v) => setS(() => selectedSupplierId = v),
                    ),
                    const SizedBox(height: 12),
                    if (warehouses.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedWarehouseId,
                        decoration: InputDecoration(labelText: 'المستودع *', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        items: warehouses.map((w) => DropdownMenuItem(value: w.id as String, child: Text(w.nameAr as String, style: GoogleFonts.cairo()))).toList(),
                        onChanged: (v) => setS(() => selectedWarehouseId = v),
                      ),
                    if (warehouses.isNotEmpty) const SizedBox(height: 12),
                    // Expected date
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setS(() => expectedDate = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(expectedDate ?? 'تاريخ التسليم المتوقع', style: GoogleFonts.cairo(color: expectedDate != null ? AppColors.textPrimary : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('الأصناف المطلوبة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (products.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedProductId,
                              isExpanded: true,
                              decoration: InputDecoration(labelText: 'منتج', labelStyle: GoogleFonts.cairo(fontSize: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                              items: products.map((p) => DropdownMenuItem(value: p['id']?.toString(), child: Text(p['name_ar'] ?? '', style: GoogleFonts.cairo(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setS(() {
                                selectedProductId = v;
                                final prod = products.firstWhere((p) => p['id'] == v, orElse: () => {});
                                if (prod['cost_price'] != null) costCtrl.text = '${prod['cost_price']}';
                              }),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(child: TextField(controller: qtyCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'كمية', labelStyle: GoogleFonts.cairo(fontSize: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)))),
                          const SizedBox(width: 4),
                          Expanded(child: TextField(controller: costCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'سعر', labelStyle: GoogleFonts.cairo(fontSize: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)))),
                          IconButton(
                            onPressed: () {
                              if (selectedProductId == null || qtyCtrl.text.isEmpty) return;
                              final prod = products.firstWhere((p) => p['id'] == selectedProductId, orElse: () => {});
                              setS(() {
                                items.add({'menu_id': selectedProductId, 'name': prod['name_ar'] ?? '', 'quantity_ordered': double.tryParse(qtyCtrl.text) ?? 1, 'unit_cost': double.tryParse(costCtrl.text) ?? 0});
                                selectedProductId = null;
                                qtyCtrl.clear();
                                costCtrl.clear();
                              });
                            },
                            icon: const Icon(Icons.add_circle, color: AppColors.success, size: 28),
                          ),
                        ],
                      ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (_, i) => ListTile(
                            dense: true,
                            title: Text('${items[i]['name']}', style: GoogleFonts.cairo(fontSize: 12)),
                            subtitle: Text('${items[i]['quantity_ordered']} × ${items[i]['unit_cost']} ج.م', style: GoogleFonts.cairo(fontSize: 11)),
                            trailing: IconButton(onPressed: () => setS(() => items.removeAt(i)), icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 18)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(controller: notesCtrl, decoration: InputDecoration(labelText: 'ملاحظات', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: items.isEmpty || selectedSupplierId == null ? null : () async {
                  Navigator.pop(ctx);
                  await _doAction(
                    () => _repo.createPurchaseOrder(
                      supplierId: selectedSupplierId!,
                      warehouseId: selectedWarehouseId ?? '',
                      items: items.map((i) => {'menu_id': i['menu_id'], 'quantity_ordered': i['quantity_ordered'], 'unit_cost': i['unit_cost']}).toList(),
                      expectedDate: expectedDate,
                      notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                    ),
                    'تم إنشاء أمر الشراء بنجاح',
                  );
                },
                child: Text('إنشاء الأمر', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateSupplierDialog({SupplierModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.nameAr ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final termsCtrl = TextEditingController(text: '30');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isEdit ? Icons.edit : Icons.person_add, color: const Color(0xFF00897B)),
            const SizedBox(width: 8),
            Text(isEdit ? 'تعديل المورد' : 'مورد جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: 'اسم المورد *', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.business)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'رقم الهاتف', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.phone)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'البريد الإلكتروني', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.email)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(labelText: 'العنوان', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.location_on)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: termsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'شروط الدفع (أيام)', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), suffixText: 'يوم'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اسم المورد مطلوب')));
                return;
              }
              Navigator.pop(ctx);
              if (isEdit) {
                await _doAction(
                  () => _repo.updateSupplier(existing.id, {
                    'name_ar': nameCtrl.text.trim(),
                    if (phoneCtrl.text.isNotEmpty) 'phone': phoneCtrl.text.trim(),
                    if (emailCtrl.text.isNotEmpty) 'email': emailCtrl.text.trim(),
                    if (addressCtrl.text.isNotEmpty) 'address': addressCtrl.text.trim(),
                    'payment_terms': int.tryParse(termsCtrl.text) ?? 30,
                  }),
                  'تم تحديث بيانات المورد',
                );
              } else {
                await _doAction(
                  () => _repo.createSupplier(
                    nameAr: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.isNotEmpty ? phoneCtrl.text.trim() : null,
                    email: emailCtrl.text.isNotEmpty ? emailCtrl.text.trim() : null,
                    address: addressCtrl.text.isNotEmpty ? addressCtrl.text.trim() : null,
                    paymentTerms: int.tryParse(termsCtrl.text) ?? 30,
                  ),
                  'تم إضافة المورد بنجاح',
                );
              }
            },
            child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة المورد', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditSupplierDialog(SupplierModel s) => _showCreateSupplierDialog(existing: s);

  void _showAddPaymentDialog(SupplierModel s) {
    final amtCtrl = TextEditingController(text: s.balance > 0 ? s.balance.toStringAsFixed(2) : '');
    String payMethod = 'cash';
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.payment, color: AppColors.success),
              const SizedBox(width: 8),
              Text('تسجيل دفعة - ${s.nameAr}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'المبلغ *',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixText: 'ج.م',
                  prefixIcon: const Icon(Icons.monetization_on, color: AppColors.success),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: payMethod,
                decoration: InputDecoration(labelText: 'طريقة الدفع', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('تحويل بنكي')),
                  DropdownMenuItem(value: 'check', child: Text('شيك')),
                  DropdownMenuItem(value: 'card', child: Text('بطاقة')),
                ],
                onChanged: (v) => setS(() => payMethod = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(labelText: 'ملاحظات', labelStyle: GoogleFonts.cairo(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () async {
                final amount = double.tryParse(amtCtrl.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل مبلغاً صحيحاً')));
                  return;
                }
                Navigator.pop(ctx);
                await _doAction(
                  () => _repo.addSupplierPayment(
                    supplierId: s.id,
                    amount: amount,
                    paymentMethod: payMethod,
                    notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                  ),
                  'تم تسجيل الدفعة بنجاح',
                );
              },
              child: Text('تأكيد الدفع', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11)),
                  Text(value, style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
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
        child: Text(label, style: GoogleFonts.cairo(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _statusBadge(String status, String label) {
    Color color;
    switch (status) {
      case 'paid': color = AppColors.success; break;
      case 'partial': color = AppColors.warning; break;
      case 'cancelled': color = AppColors.error; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _emptyState(IconData icon, String message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: const Color(0xFFBDBDBD)),
            const SizedBox(height: 12),
            Text(message, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      );

  String _formatDate(dynamic date) {
    if (date == null) return '—';
    try {
      final d = DateTime.parse(date.toString()).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date.toString().substring(0, 10);
    }
  }
}
