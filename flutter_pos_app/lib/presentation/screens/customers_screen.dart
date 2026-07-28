import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customers_repository.dart';
import '../../main.dart';

class CustomersScreen extends StatefulWidget {
  final Widget? drawer;
  const CustomersScreen({super.key, this.drawer});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomersRepository _repo = CustomersRepository();
  List<CustomerModel> _customers = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getCustomers(search: _searchQuery.isNotEmpty ? _searchQuery : null);
      if (mounted) setState(() => _customers = list);
    } catch (e) {
      debugPrint('❌ Error loading customers data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
          title: Text('إدارة العملاء', style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) {
                  _searchQuery = v;
                  Future.delayed(const Duration(milliseconds: 500), _loadData);
                },
                decoration: const InputDecoration(
                  hintText: 'بحث باسم أو رقم هاتف...',
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                ),
              ),
            ),
            if (_customers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    _summaryChip('${_customers.length} عميل', Icons.people, AppColors.primary),
                    const SizedBox(width: 8),
                    _summaryChip(
                      '${_customers.fold(0.0, (s, c) => s + c.totalSpent).toStringAsFixed(0)} ج.م',
                      Icons.attach_money,
                      AppColors.success,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _customers.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: _customers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final c = _customers[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  radius: 24,
                                  child: Text(
                                    c.name.isNotEmpty ? c.name[0] : 'ع',
                                    style: GoogleFonts.cairo(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  c.name,
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (c.phone != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 12, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(c.phone!,
                                              style: GoogleFonts.cairo(
                                                  fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _miniStat('${c.totalOrders} طلب', AppColors.primary),
                                        const SizedBox(width: 8),
                                        _miniStat('${c.totalSpent.toStringAsFixed(0)} ج.م', AppColors.success),
                                        if (c.loyaltyPoints > 0) ...[
                                          const SizedBox(width: 8),
                                          _miniStat('${c.loyaltyPoints.toStringAsFixed(0)} نقطة', AppColors.warning),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: AppColors.primary),
                                  onSelected: (value) {
                                    if (value == 'edit') _showEditCustomerDialog(c);
                                    if (value == 'details') _showCustomerDetails(c);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'details', child: Text('عرض التفاصيل')),
                                    const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddCustomerDialog,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: Text('إضافة عميل', style: GoogleFonts.cairo(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _summaryChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _miniStat(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: GoogleFonts.cairo(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showCustomerDetails(CustomerModel c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  c.name.isNotEmpty ? c.name[0] : 'ع',
                  style: GoogleFonts.cairo(
                      color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ),
              const SizedBox(height: 10),
              Text(c.name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
              if (c.phone != null)
                Text(c.phone!, style: GoogleFonts.cairo(color: AppColors.textSecondary)),
              if (c.address != null)
                Text(c.address!, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _detailStat('إجمالي الطلبات', '${c.totalOrders}', AppColors.primary),
                  _detailStat('إجمالي الإنفاق', '${c.totalSpent.toStringAsFixed(2)} ج.م', AppColors.success),
                  _detailStat('نقاط الولاء', c.loyaltyPoints.toStringAsFixed(0), AppColors.warning),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditCustomerDialog(c);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text('تعديل بيانات العميل', style: GoogleFonts.cairo()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('إضافة عميل جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم العميل *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  await _repo.createCustomer(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                    address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                  );
                  if (!mounted || !ctx.mounted) return;
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إضافة العميل بنجاح ✅'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e')),
                    );
                  }
                }
              },
              child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCustomerDialog(CustomerModel c) {
    final nameCtrl = TextEditingController(text: c.name);
    final phoneCtrl = TextEditingController(text: c.phone ?? '');
    final addressCtrl = TextEditingController(text: c.address ?? '');
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تعديل بيانات العميل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم العميل'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  await _repo.updateCustomer(
                    id: c.id,
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                    address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                  );
                  if (!mounted || !ctx.mounted) return;
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث العميل بنجاح ✅'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e')),
                    );
                  }
                }
              },
              child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 12),
          Text('لا يوجد عملاء مسجلين',
              style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 6),
          Text('اضغط + لإضافة عميل جديد',
              style: GoogleFonts.cairo(color: const Color(0xFFBDBDBD), fontSize: 12)),
        ],
      ),
    );
  }
}
