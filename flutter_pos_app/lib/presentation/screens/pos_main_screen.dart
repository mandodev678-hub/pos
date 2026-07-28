import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/user_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/pos_repository.dart';
import '../../main.dart';
import '../providers/cart_provider.dart';
import '../providers/kds_provider.dart';
import 'checkout_modal.dart';
import 'tables_screen.dart';
import 'shift_screen.dart';
import 'login_screen.dart';

class PosMainScreen extends StatefulWidget {
  final UserModel user;
  final bool embeddedMode;
  final Widget? drawer;
  const PosMainScreen({super.key, required this.user, this.embeddedMode = false, this.drawer});

  @override
  State<PosMainScreen> createState() => _PosMainScreenState();
}

class _PosMainScreenState extends State<PosMainScreen> {
  final PosRepository _posRepository = PosRepository();
  List<CategoryModel> _categories = [];
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = true;

  String _sellerName = 'مطعم ومأكولات زمام';
  String _vatNumber = '300000000000003';
  double _taxRate = 15;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _posRepository.getSettings();
      final store = settings['store'] as Map<String, dynamic>?;
      if (store != null) {
        _sellerName = store['storeName'] as String? ?? _sellerName;
        _vatNumber = store['taxNumber'] as String? ?? _vatNumber;
        _taxRate = (store['taxRate'] as num?)?.toDouble() ?? _taxRate;
      }
    } catch (_) {}
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final cats = await _posRepository.getCategories();
      final products = await _posRepository.getMenuItems();
      setState(() {
        _categories = cats;
        _allProducts = products;
        _filterProducts();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل المنيو من الباك إند: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesCat = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
        final matchesQuery = _searchQuery.isEmpty || p.nameAr.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCat && matchesQuery;
      }).toList();
    });
  }

  // ─── Order Type Tabs ────────────────────────────────────────────────────────
  Widget _buildOrderTypeTabs(CartProvider cart) {
    final types = [
      ('dine_in', 'صالة', Icons.table_restaurant),
      ('takeaway', 'سفري', Icons.takeout_dining),
      ('delivery', 'توصيل', Icons.delivery_dining),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: types.map((t) {
          final isSelected = cart.orderType == t.$1;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                cart.setOrderType(t.$1);
                if (t.$1 == 'dine_in') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TablesScreen(onTableSelected: (n) => cart.setTableNumber(n)),
                    ),
                  );
                } else if (t.$1 == 'delivery') {
                  _showDeliveryDetailsDialog(context, cart);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.$3, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      t.$2,
                      style: GoogleFonts.cairo(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Category Pills ──────────────────────────────────────────────────────────
  Widget _buildCategoryPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _categoryChip('الكل', null, Icons.grid_view_rounded),
          ..._categories.map((c) => _categoryChip(c.nameAr, c.id, _getCategoryIcon(c.nameAr))),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    if (name.contains('برجر')) return Icons.lunch_dining;
    if (name.contains('بيتزا')) return Icons.local_pizza;
    if (name.contains('دجاج') || name.contains('مشويات') || name.contains('كباب')) return Icons.kebab_dining;
    if (name.contains('مشروبات') || name.contains('عصير')) return Icons.local_drink;
    if (name.contains('حلويات') || name.contains('آيس')) return Icons.icecream;
    return Icons.restaurant_menu;
  }

  Widget _categoryChip(String label, String? catId, IconData icon) {
    final isSelected = _selectedCategoryId == catId;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCategoryId = catId;
        _filterProducts();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Product Grid ────────────────────────────────────────────────────────────
  Widget _buildProductGrid(CartProvider cart) {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 56, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 10),
            Text("لا تتوفر وجبات في هذا القسم", style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final p = _filteredProducts[index];
        final icon = _getCategoryIcon(p.nameAr);
        final gradient = _getProductGradient(index);

        return GestureDetector(
          onTap: () => cart.addToCart(p),
          child: Card(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header image or gradient placeholder
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(icon, size: 44, color: Colors.white.withValues(alpha: 0.9)),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${p.price.toStringAsFixed(0)} ج.م",
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nameAr,
                              style: GoogleFonts.cairo(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${p.price.toStringAsFixed(2)} ج.م",
                              style: GoogleFonts.cairo(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_shopping_cart_rounded, size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  LinearGradient _getProductGradient(int index) {
    final gradients = [
      const LinearGradient(colors: [Color(0xFF4568DC), Color(0xFFB06AB3)]),
      const LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFDD2476)]),
      const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
      const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
      const LinearGradient(colors: [Color(0xFFFF8008), Color(0xFFFFC837)]),
      const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
    ];
    return gradients[index % gradients.length];
  }

  // ─── Cart Panel ──────────────────────────────────────────────────────────────
  Widget _buildCartPanel(CartProvider cart) {
    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Column(
        children: [
          // Cart header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart, color: AppColors.primary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "سلة الطلب",
                          style: GoogleFonts.cairo(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (cart.totalQuantity > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${cart.totalQuantity}",
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (cart.items.isNotEmpty)
                      TextButton.icon(
                        onPressed: cart.clearCart,
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        label: Text("مسح الكل", style: GoogleFonts.cairo(color: AppColors.error, fontSize: 12)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildOrderTypeTabs(cart),
                if (cart.orderType == 'dine_in' && cart.selectedTableNumber != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      "الطاولة رقم: ${cart.selectedTableNumber}",
                      style: GoogleFonts.cairo(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
                if (cart.orderType == 'delivery') ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _showDeliveryDetailsDialog(context, cart),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              cart.deliveryAddress != null && cart.deliveryAddress!.isNotEmpty
                                  ? "التوصيل: ${cart.customerName ?? 'عميل'} - ${cart.deliveryAddress}"
                                  : "اضغط لإضافة بيانات عنوان التوصيل والعميل 📍",
                              style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.edit, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Cart items
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 48, color: Color(0xFFBDBDBD)),
                        const SizedBox(height: 8),
                        Text(
                          "السلة فارغة",
                          style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        Text(
                          "اضغط على وجبة للإضافة",
                          style: GoogleFonts.cairo(color: const Color(0xFFBDBDBD), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.nameAr,
                                    style: GoogleFonts.cairo(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "${item.product.price.toStringAsFixed(2)} ج.م / قطعة",
                                    style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16, color: AppColors.error),
                                    onPressed: () => cart.updateQuantity(index, item.quantity - 1),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Text("${item.quantity}", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                                    onPressed: () => cart.updateQuantity(index, item.quantity + 1),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Cart totals & checkout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Column(
              children: [
                _totalRow("المجموع الفرعي:", "${cart.subtotal.toStringAsFixed(2)} ج.م", false),
                const SizedBox(height: 4),
                _totalRow("الضريبة (14%):", "${cart.tax.toStringAsFixed(2)} ج.م", false),
                const Divider(),
                _totalRow("الإجمالي:", "${cart.total.toStringAsFixed(2)} ج.م", true),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: cart.items.isEmpty
                        ? null
                        : () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => CheckoutModal(
                                totalAmount: cart.total,
                                vatAmount: cart.tax,
                                sellerName: _sellerName,
                                vatNumber: _vatNumber,
                                onPaymentConfirmed: (method, paid) async {
                                  final posRepo = PosRepository();
                                  try {
                                    final orderResult = await posRepo.createOrder(
                                      orderType: cart.orderType,
                                      items: cart.items,
                                      tableNumber: cart.selectedTableNumber,
                                      customerName: cart.customerName,
                                      customerPhone: cart.customerPhone,
                                      deliveryAddress: cart.deliveryAddress,
                                      discount: cart.discount,
                                      tax: cart.tax,
                                      paymentMethod: method,
                                      isPaid: true,
                                    );
                                    final orderId = orderResult['id'] as String? ?? orderResult['orderId'] as String?;
                                    if (orderId != null) {
                                      posRepo.printOrder(orderId);
                                    }
                                    cart.clearCart();
                                    if (mounted) {
                                      Navigator.of(context).pop(); // Close cart bottom sheet
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('تم إتمام البيع وحفظ الفاتورة بنجاح ✅'),
                                          backgroundColor: Color(0xFF2E7D32),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                    label: Text(
                      "إتمام الدفع",
                      style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, bool bold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: GoogleFonts.cairo(
            color: bold ? AppColors.primary : AppColors.textPrimary,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildKdsAction(BuildContext context) {
    final kds = context.watch<KdsProvider>();
    return IconButton(
      icon: kds.readyCount > 0
          ? Badge(
              label: Text('${kds.readyCount}'),
              backgroundColor: const Color(0xFF2E7D32),
              child: const Icon(Icons.kitchen, color: Colors.white),
            )
          : const Icon(Icons.kitchen_outlined, color: Colors.white),
      tooltip: "الطلبات الجاهزة",
      onPressed: kds.readyCount > 0
          ? () => _showReadyOrdersSheet(context, kds)
          : null,
    );
  }

  void _showReadyOrdersSheet(BuildContext context, KdsProvider kds) {
    kds.acknowledgeReadyOrders();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'الطلبات الجاهزة للاستلام',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (kds.readyOrders.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                        const SizedBox(height: 8),
                        Text('لا توجد طلبات جاهزة حالياً', style: GoogleFonts.cairo(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                ...kds.readyOrders.map((order) => Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'طلب #${order.orderNumber}',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            if (order.tableNumber != null)
                              Text(
                                'طاولة رقم: ${order.tableNumber}',
                                style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            if (order.customerName != null)
                              Text(
                                order.customerName!,
                                style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${order.total.toStringAsFixed(2)} ج.م',
                        style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('تم', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
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
            child: Text('تأكيد الخروج', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isTablet = MediaQuery.of(context).size.width >= 720;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: widget.drawer,
        appBar: widget.embeddedMode
            ? AppBar(
                backgroundColor: AppColors.primary,
                automaticallyImplyLeading: false,
                leading: Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                    tooltip: 'القائمة الرئيسية',
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                title: Text(
                  'الكاشير • ${widget.user.nameAr}',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                actions: [
                  if (cart.items.isNotEmpty)
                    IconButton(
                      icon: Badge(
                        label: Text('${cart.totalQuantity}'),
                        child: const Icon(Icons.shopping_cart, color: Colors.white),
                      ),
                      tooltip: "سلة الطلبات",
                      onPressed: () => _openCartBottomSheet(context, cart),
                    ),
                  _buildKdsAction(context),
                  IconButton(
                    icon: const Icon(Icons.table_restaurant, color: Colors.white),
                    tooltip: "الطاولات",
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TablesScreen(onTableSelected: (n) => cart.setTableNumber(n)),
                      ),
                    ),
                  ),
                ],
              )
            : AppBar(
                backgroundColor: AppColors.primary,
                title: Row(
                  children: [
                    const Icon(Icons.point_of_sale, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text("زمام POS - ${widget.user.nameAr}", style: GoogleFonts.cairo(color: Colors.white)),
                  ],
                ),
                actions: [
                  _buildKdsAction(context),
                  IconButton(
                    icon: const Icon(Icons.table_restaurant, color: Colors.white),
                    tooltip: "الصالة والطاولات",
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TablesScreen(onTableSelected: (n) => cart.setTableNumber(n)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time, color: Colors.white),
                    tooltip: "إدارة الوردية",
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: "تسجيل الخروج",
                    onPressed: () => _confirmLogout(context),
                  ),
                ],
              ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: TextField(
                            onChanged: (val) {
                              _searchQuery = val;
                              _filterProducts();
                            },
                            decoration: InputDecoration(
                              hintText: "بحث عن وجبة بالاسم أو الباركود...",
                              hintStyle: GoogleFonts.cairo(color: Colors.grey),
                              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _buildCategoryPills(),
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: _buildProductGrid(cart)),
                      ],
                    ),
                  ),
                  if (isTablet) _buildCartPanel(cart),
                ],
              ),
        bottomSheet: !isTablet && cart.items.isNotEmpty
            ? GestureDetector(
                onTap: () => _openCartBottomSheet(context, cart),
                child: Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${cart.totalQuantity} صنف',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.shopping_cart, color: Colors.white, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            'عرض السلة',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${cart.total.toStringAsFixed(2)} ج.م',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  void _openCartBottomSheet(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer<CartProvider>(
        builder: (context, activeCart, _) => Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: _buildCartPanel(activeCart),
          ),
        ),
      ),
    );
  }

  void _showDeliveryDetailsDialog(BuildContext context, CartProvider cart) {
    final nameController = TextEditingController(text: cart.customerName ?? '');
    final phoneController = TextEditingController(text: cart.customerPhone ?? '');
    final addressController = TextEditingController(text: cart.deliveryAddress ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.delivery_dining, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('بيانات عنوان التوصيل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم العميل',
                    prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                    labelStyle: GoogleFonts.cairo(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                    labelStyle: GoogleFonts.cairo(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'عنوان التوصيل (الشارع / العمارة / الشقة)',
                    prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
                    labelStyle: GoogleFonts.cairo(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                cart.setCustomerDetails(
                  name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                  phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                );
                Navigator.pop(dialogCtx);
              },
              child: Text('حفظ البيانات', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
