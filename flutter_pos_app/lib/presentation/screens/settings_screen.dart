import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel? user;
  final Widget? drawer;
  const SettingsScreen({super.key, this.user, this.drawer});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final SettingsRepository _repo = SettingsRepository();
  late TabController _tabController;

  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _settings = {};

  // Store Controllers
  final _storeNameArCtrl = TextEditingController();
  final _storeNameEnCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxNumberCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController();
  final _serviceRateCtrl = TextEditingController();
  final _commercialRegisterCtrl = TextEditingController();

  // Workflow Controllers
  final _orderPrefixCtrl = TextEditingController();
  final _orderStartCtrl = TextEditingController();

  // Receipt Controllers
  final _headerTextCtrl = TextEditingController();
  final _footerTextCtrl = TextEditingController();

  // HR Controllers
  final _graceCountCtrl = TextEditingController();
  final _deductionValueCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storeNameArCtrl.dispose();
    _storeNameEnCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _taxNumberCtrl.dispose();
    _taxRateCtrl.dispose();
    _serviceRateCtrl.dispose();
    _commercialRegisterCtrl.dispose();
    _orderPrefixCtrl.dispose();
    _orderStartCtrl.dispose();
    _headerTextCtrl.dispose();
    _footerTextCtrl.dispose();
    _graceCountCtrl.dispose();
    _deductionValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.getSettings();
      if (mounted) {
        setState(() {
          _settings = data;
          _populateControllers();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الإعدادات: $e', style: GoogleFonts.cairo()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populateControllers() {
    final store = _settings['store'] as Map<String, dynamic>? ?? {};
    _storeNameArCtrl.text = store['storeName'] ?? store['store_name'] ?? '';
    _storeNameEnCtrl.text = store['storeNameEn'] ?? store['store_name_en'] ?? '';
    _phoneCtrl.text = store['phone'] ?? '';
    _addressCtrl.text = store['address'] ?? '';
    _taxNumberCtrl.text = store['taxNumber'] ?? '';
    _taxRateCtrl.text = '${store['taxRate'] ?? 15}';
    _serviceRateCtrl.text = '${store['serviceRate'] ?? 0}';
    _commercialRegisterCtrl.text = store['commercialRegister'] ?? '';

    final wf = _settings['workflow'] as Map<String, dynamic>? ?? {};
    _orderPrefixCtrl.text = wf['orderNumberPrefix'] ?? 'ORD-';
    _orderStartCtrl.text = '${wf['orderNumberStart'] ?? 1000}';

    final rec = _settings['receipt'] as Map<String, dynamic>? ?? {};
    _headerTextCtrl.text = rec['headerText'] ?? '';
    _footerTextCtrl.text = rec['footerText'] ?? '';

    final hr = _settings['hr'] as Map<String, dynamic>? ?? {};
    final latePolicy = hr['payrollLatePolicy'] as Map<String, dynamic>? ?? {};
    _graceCountCtrl.text = '${latePolicy['graceCount'] ?? 0}';
    _deductionValueCtrl.text = '${latePolicy['deductionValue'] ?? 0}';
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      // Build updated payload from controllers & state
      final storeMap = Map<String, dynamic>.from(_settings['store'] ?? {});
      storeMap['storeName'] = _storeNameArCtrl.text.trim();
      storeMap['storeNameEn'] = _storeNameEnCtrl.text.trim();
      storeMap['phone'] = _phoneCtrl.text.trim();
      storeMap['address'] = _addressCtrl.text.trim();
      storeMap['taxNumber'] = _taxNumberCtrl.text.trim();
      storeMap['taxRate'] = double.tryParse(_taxRateCtrl.text.trim()) ?? 15.0;
      storeMap['serviceRate'] = double.tryParse(_serviceRateCtrl.text.trim()) ?? 0.0;
      storeMap['commercialRegister'] = _commercialRegisterCtrl.text.trim();

      final wfMap = Map<String, dynamic>.from(_settings['workflow'] ?? {});
      wfMap['orderNumberPrefix'] = _orderPrefixCtrl.text.trim();
      wfMap['orderNumberStart'] = int.tryParse(_orderStartCtrl.text.trim()) ?? 1000;

      final recMap = Map<String, dynamic>.from(_settings['receipt'] ?? {});
      recMap['headerText'] = _headerTextCtrl.text.trim();
      recMap['footerText'] = _footerTextCtrl.text.trim();

      final hrMap = Map<String, dynamic>.from(_settings['hr'] ?? {});
      final latePolicy = Map<String, dynamic>.from(hrMap['payrollLatePolicy'] ?? {});
      latePolicy['graceCount'] = int.tryParse(_graceCountCtrl.text.trim()) ?? 0;
      latePolicy['deductionValue'] = double.tryParse(_deductionValueCtrl.text.trim()) ?? 0.0;
      hrMap['payrollLatePolicy'] = latePolicy;

      final payload = {
        'store': storeMap,
        'hardware': _settings['hardware'] ?? {},
        'workflow': wfMap,
        'receipt': recMap,
        'notifications': _settings['notifications'] ?? {},
        'inventory': _settings['inventory'] ?? {},
        'hr': hrMap,
        'system': _settings['system'] ?? {},
      };

      final updated = await _repo.updateSettings(payload);
      if (mounted) {
        setState(() => _settings = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('تم حفظ الإعدادات بنجاح في النظام', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء حفظ الإعدادات: $e', style: GoogleFonts.cairo()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user?.role == 'admin' || widget.user?.role == 'manager';

    if (!isAdmin) {
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
            title: Text('إعدادات النظام', style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('صلاحية محظورة', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('إعدادات النظام متاحة لمدير النظام والمديرين فقط', style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary)),
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
          title: Text('إعدادات النظام والمنشأة', style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'تحديث البيانات',
              onPressed: _loadSettings,
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
                Tab(icon: Icon(Icons.store, size: 18), text: 'المنشأة'),
                Tab(icon: Icon(Icons.tune, size: 18), text: 'سير العمل والتشغيل'),
                Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'الفاتورة والطباعة'),
                Tab(icon: Icon(Icons.notifications_active, size: 18), text: 'التنبيهات والنظام'),
                Tab(icon: Icon(Icons.badge, size: 18), text: 'سياسة الموظفين'),
              ],
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildStoreTab(),
                  _buildWorkflowTab(),
                  _buildReceiptTab(),
                  _buildSystemNotificationsTab(),
                  _buildHrTab(),
                ],
              ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _saving ? null : _saveSettings,
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded, color: Colors.white),
            label: Text(
              _saving ? 'جاري الحفظ...' : 'حفظ التغيرات بالإعدادات',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Tab 1: Store Info ─────────────────────────────────────────────────────
  Widget _buildStoreTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'بيانات المنشأة والمتجر',
          icon: Icons.storefront_rounded,
          children: [
            _buildTextField(_storeNameArCtrl, 'اسم المتجر بالعربي', Icons.store, hint: 'مطعم الذواقة'),
            const SizedBox(height: 12),
            _buildTextField(_storeNameEnCtrl, 'اسم المتجر بالإنجليزية', Icons.language, hint: 'Gourmet Restaurant'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField(_phoneCtrl, 'رقم الهاتف', Icons.phone, keyboardType: TextInputType.phone)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_commercialRegisterCtrl, 'السجل التجاري', Icons.assignment_ind)),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(_addressCtrl, 'عنوان المنشأة', Icons.location_on, hint: 'الرياض، المملكة العربية السعودية'),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'الضرائب والرسوم المالية',
          icon: Icons.request_quote_rounded,
          children: [
            _buildTextField(_taxNumberCtrl, 'الرقم الضريبي (VAT)', Icons.numbers, hint: '300000000000003'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _taxRateCtrl,
                    'نسبة القيمة المضافة (%)',
                    Icons.percent,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _serviceRateCtrl,
                    'رسوم الخدمة (%)',
                    Icons.room_service,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─── Tab 2: Workflow Tab ───────────────────────────────────────────────────
  Widget _buildWorkflowTab() {
    final wf = Map<String, dynamic>.from(_settings['workflow'] ?? {});
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'أرقام وحلقات الطلبات',
          icon: Icons.tag,
          children: [
            Row(
              children: [
                Expanded(child: _buildTextField(_orderPrefixCtrl, 'بادئة رقم الطلب', Icons.code, hint: 'ORD-')),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_orderStartCtrl, 'الرقم البادئ للطلب', Icons.pin, keyboardType: TextInputType.number)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'قواعد وسير العمل بالصالة والبيع',
          icon: Icons.alt_route_rounded,
          children: [
            _buildSwitchTile(
              title: 'قبول تلقائي للطلبات أونلاين',
              subtitle: 'قبول وتمرير طلبات المتجر الإلكتروني تلقائياً',
              value: wf['autoAcceptOnline'] ?? false,
              onChanged: (v) => setState(() => (_settings['workflow'] ??={})['autoAcceptOnline'] = v),
            ),
            _buildSwitchTile(
              title: 'تفعيل خدمة التوصيل',
              subtitle: 'السماح بإنشاء وتتبع طلبات التوصيل وسائقي الدليفري',
              value: wf['enableDelivery'] ?? true,
              onChanged: (v) => setState(() => (_settings['workflow'] ??={})['enableDelivery'] = v),
            ),
            _buildSwitchTile(
              title: 'طلب موافقة المدير لإلغاء العناصر',
              subtitle: 'يتطلب رمز موافقة المدير لحذف أي صنف من الفاتورة',
              value: wf['requireManagerForVoid'] ?? true,
              onChanged: (v) => setState(() => (_settings['workflow'] ??={})['requireManagerForVoid'] = v),
            ),
            _buildSwitchTile(
              title: 'السماح بالإلغاء بدون سبب',
              subtitle: 'تمكين الكاشير من إلغاء الفاتورة دون تحديد سبب الإلغاء',
              value: wf['allowCancelWithoutReason'] ?? false,
              onChanged: (v) => setState(() => (_settings['workflow'] ??={})['allowCancelWithoutReason'] = v),
            ),
            _buildSwitchTile(
              title: 'إكمال تلقائي للطلب عند الدفع',
              subtitle: 'تغيير حالة الطلب لمكتمل فور تأكيد السداد',
              value: wf['autoCompleteOrders'] ?? false,
              onChanged: (v) => setState(() => (_settings['workflow'] ??={})['autoCompleteOrders'] = v),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Tab 3: Receipt & Hardware ─────────────────────────────────────────────
  Widget _buildReceiptTab() {
    final rec = Map<String, dynamic>.from(_settings['receipt'] ?? {});
    final hw = Map<String, dynamic>.from(_settings['hardware'] ?? {});
    final wf = Map<String, dynamic>.from(_settings['workflow'] ?? {});

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'محتوى وشكل فاتورة العميل',
          icon: Icons.receipt_long_rounded,
          children: [
            _buildSwitchTile(
              title: 'إظهار الشعار (Logo)',
              subtitle: 'طباعة شعار المتجر أعلى الإيصال',
              value: rec['showLogo'] ?? true,
              onChanged: (v) => setState(() => (_settings['receipt'] ??={})['showLogo'] = v),
            ),
            _buildSwitchTile(
              title: 'إظهار الرقم الضريبي',
              subtitle: 'طباعة الرقم الضريبي للمنشأة بالفاتورة',
              value: rec['showTaxNumber'] ?? true,
              onChanged: (v) => setState(() => (_settings['receipt'] ??={})['showTaxNumber'] = v),
            ),
            _buildSwitchTile(
              title: 'إظهار رمز QR الضريبي (ZATCA)',
              subtitle: 'طباعة باركود الاستجابة السريعة على الفاتورة الإلكترونية',
              value: rec['showQRCode'] ?? true,
              onChanged: (v) => setState(() => (_settings['receipt'] ??={})['showQRCode'] = v),
            ),
            _buildSwitchTile(
              title: 'إظهار معلومات العميل',
              subtitle: 'طباعة اسم العميل ورقم هاتفه بالفاتورة',
              value: rec['showCustomerInfo'] ?? true,
              onChanged: (v) => setState(() => (_settings['receipt'] ??={})['showCustomerInfo'] = v),
            ),
            const SizedBox(height: 12),
            _buildTextField(_headerTextCtrl, 'نص ترويسة الفاتورة (Header Text)', Icons.vertical_align_top),
            const SizedBox(height: 12),
            _buildTextField(_footerTextCtrl, 'نص تذييل الفاتورة (Footer Text)', Icons.vertical_align_bottom, hint: 'شكراً لزيارتكم'),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'إعدادات الطابعة والدرج الحسابي',
          icon: Icons.print_rounded,
          children: [
            _buildSwitchTile(
              title: 'الطباعة المباشرة التلقائية',
              subtitle: 'طباعة الفاتورة فور إتمام الدفع بدون معاينة',
              value: rec['autoPrint'] ?? true,
              onChanged: (v) => setState(() => (_settings['receipt'] ??={})['autoPrint'] = v),
            ),
            _buildSwitchTile(
              title: 'طباعة أمر المطبخ (KDS)',
              subtitle: 'إرسال نسخة أمر التشغيل للمطبخ (بدون أسعار)',
              value: wf['printKitchenReceipt'] ?? true,
              onChanged: (v) => setState(() => (_settings['workflow'] ??={})['printKitchenReceipt'] = v),
            ),
            _buildSwitchTile(
              title: 'فتح الدرج النقدي تلقائياً',
              subtitle: 'فتح درج الكاشير عند الدفع النقدي',
              value: hw['enableCashDrawer'] ?? true,
              onChanged: (v) => setState(() => (_settings['hardware'] ??={})['enableCashDrawer'] = v),
            ),
            _buildSwitchTile(
              title: 'تفعيل شاشة المطبخ (Kitchen Display System)',
              subtitle: 'عرض الطلبات مباشرة على شاشة KDS بدلاً من الطباعة الورقية فقط',
              value: hw['enableKitchenDisplay'] ?? false,
              onChanged: (v) => setState(() => (_settings['hardware'] ??={})['enableKitchenDisplay'] = v),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Tab 4: System & Notifications ─────────────────────────────────────────
  Widget _buildSystemNotificationsTab() {
    final notif = Map<String, dynamic>.from(_settings['notifications'] ?? {});
    final sys = Map<String, dynamic>.from(_settings['system'] ?? {});

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'إعدادات التنبيهات والأصوات',
          icon: Icons.volume_up_rounded,
          children: [
            _buildSwitchTile(
              title: 'تفعيل التنبيهات الصوتية',
              subtitle: 'تشغيل أصوات التنبيه عند الأحداث المهمة',
              value: notif['soundEnabled'] ?? true,
              onChanged: (v) => setState(() => (_settings['notifications'] ??={})['soundEnabled'] = v),
            ),
            _buildSwitchTile(
              title: 'تنبيه الطلبات الجديدة',
              subtitle: 'إشعار صوتی وفوري عند استقبال طلب جديد',
              value: notif['newOrderAlert'] ?? true,
              onChanged: (v) => setState(() => (_settings['notifications'] ??={})['newOrderAlert'] = v),
            ),
            _buildSwitchTile(
              title: 'تنبيه النقص بالمخزون',
              subtitle: 'تنبيه الكاشير عند وصول المادة للحد الأدنى',
              value: notif['lowStockAlert'] ?? true,
              onChanged: (v) => setState(() => (_settings['notifications'] ??={})['lowStockAlert'] = v),
            ),
            _buildSwitchTile(
              title: 'تذكير إغلاق الوردية',
              subtitle: 'تنبيه بموعد تسليم الوردية وإقفال الصندوق',
              value: notif['shiftReminder'] ?? true,
              onChanged: (v) => setState(() => (_settings['notifications'] ??={})['shiftReminder'] = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'إعدادات النظام والعملة',
          icon: Icons.language_rounded,
          children: [
            ListTile(
              title: Text('العملة الرئيسية للنظام', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              subtitle: Text('العملة الحالية: ${sys['currency'] ?? 'SAR'} (${sys['currencySymbol'] ?? 'ر.س'})', style: GoogleFonts.cairo()),
              trailing: DropdownButton<String>(
                value: sys['currency'] ?? 'SAR',
                items: const [
                  DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
                  DropdownMenuItem(value: 'EGP', child: Text('جنيه مصري (EGP)')),
                  DropdownMenuItem(value: 'AED', child: Text('درهم إماراتي (AED)')),
                  DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
                  DropdownMenuItem(value: 'KWD', child: Text('دينار كويتي (KWD)')),
                  DropdownMenuItem(value: 'QAR', child: Text('ريال قطري (QAR)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      final sysMap = Map<String, dynamic>.from(_settings['system'] ?? {});
                      sysMap['currency'] = val;
                      _settings['system'] = sysMap;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Tab 5: HR Policies ────────────────────────────────────────────────────
  Widget _buildHrTab() {
    final hr = Map<String, dynamic>.from(_settings['hr'] ?? {});
    final latePolicy = Map<String, dynamic>.from(hr['payrollLatePolicy'] ?? {});

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'سياسة التأخير والجزاءات للموظفين',
          icon: Icons.alarm_off_rounded,
          children: [
            _buildSwitchTile(
              title: 'تفعيل خصم التأخير التلقائي',
              subtitle: 'خصم التأخيرات تلقائياً عند مسح الحضور والانصراف',
              value: latePolicy['enabled'] ?? false,
              onChanged: (v) {
                setState(() {
                  final hrMap = Map<String, dynamic>.from(_settings['hr'] ?? {});
                  final lp = Map<String, dynamic>.from(hrMap['payrollLatePolicy'] ?? {});
                  lp['enabled'] = v;
                  hrMap['payrollLatePolicy'] = lp;
                  _settings['hr'] = hrMap;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(_graceCountCtrl, 'عدد مرات السماح بالتأخير شهرياً (Grace Count)', Icons.history, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildTextField(_deductionValueCtrl, 'قيمة الخصم عند التجاوز', Icons.money_off, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
      ],
    );
  }

  // ─── Helper Widgets ────────────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.cairo(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
    );
  }
}
