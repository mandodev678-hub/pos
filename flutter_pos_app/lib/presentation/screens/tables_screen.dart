import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/table_model.dart';
import '../../data/repositories/table_repository.dart';

class TablesScreen extends StatefulWidget {
  final Function(String tableNumber) onTableSelected;

  const TablesScreen({super.key, required this.onTableSelected});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  final TableRepository _tableRepository = TableRepository();
  List<TableModel> _tables = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTables();
  }

  Future<void> _fetchTables() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final tables = await _tableRepository.getTables();
      if (mounted) setState(() => _tables = tables);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _tables = List.generate(12, (index) => TableModel(
            id: 't_$index',
            tableNumber: '${index + 1}',
            capacity: 4,
            status: index % 3 == 0 ? 'occupied' : 'available',
          ));
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getTableColor(String status) {
    switch (status) {
      case 'occupied':
        return Colors.redAccent;
      case 'reserved':
        return Colors.orangeAccent;
      case 'bill_printed':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  String _getTableStatusText(String status) {
    switch (status) {
      case 'occupied':
        return 'مشغولة';
      case 'reserved':
        return 'محجوزة';
      case 'bill_printed':
        return 'طلب الفاتورة';
      default:
        return 'متاحة';
    }
  }

  void _showTableDetails(TableModel table) {
    if (table.isAvailable) {
      widget.onTableSelected(table.tableNumber);
      Navigator.pop(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A3D),
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
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.table_restaurant, color: _getTableColor(table.status), size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'طاولة #${table.tableNumber}',
                    style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTableColor(table.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getTableStatusText(table.status),
                  style: GoogleFonts.cairo(color: _getTableColor(table.status), fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: Colors.white24, height: 24),
              if (table.currentOrders.isNotEmpty) ...[
                Text('الطلبات النشطة:', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                ...table.currentOrders.map((o) => Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلب #${o.orderNumber}',
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          if (o.customerName != null)
                            Text(
                              o.customerName!,
                              style: GoogleFonts.cairo(color: Colors.white60, fontSize: 13),
                            ),
                        ],
                      ),
                      Text(
                        '${o.total.toStringAsFixed(2)} ج.م',
                        style: GoogleFonts.cairo(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الإجمالي:', style: GoogleFonts.cairo(color: Colors.white70)),
                    Text(
                      '${table.totalAmount.toStringAsFixed(2)} ج.م',
                      style: GoogleFonts.cairo(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ] else
                Text('لا توجد طلبات نشطة', style: GoogleFonts.cairo(color: Colors.white60)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleSelectTable(table),
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: Text('إضافة طلب', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  if (table.currentOrders.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showTransferDialog(table),
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: Text('نقل الطلب', style: GoogleFonts.cairo()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSelectTable(TableModel table) {
    Navigator.pop(context);
    widget.onTableSelected(table.tableNumber);
  }

  void _showTransferDialog(TableModel sourceTable) {
    final availableTables = _tables.where((t) =>
      t.isAvailable && t.tableNumber != sourceTable.tableNumber
    ).toList();

    if (availableTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد طاولات فارغة للنقل إليها')),
      );
      return;
    }

    Navigator.pop(context);
    String? selectedTable;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2A2A3D),
          title: Text(
            'نقل الطلب من طاولة #${sourceTable.tableNumber}',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              final items = availableTables.map((t) => t.tableNumber).toList();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('اختر الطاولة المستهدفة:', style: GoogleFonts.cairo(color: Colors.white70)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedTable,
                        hint: Text('اختر طاولة...', style: GoogleFonts.cairo(color: Colors.white60)),
                        dropdownColor: const Color(0xFF1E1E2E),
                        items: items.map((tn) => DropdownMenuItem(
                          value: tn,
                          child: Text('طاولة #$tn', style: GoogleFonts.cairo(color: Colors.white)),
                        )).toList(),
                        onChanged: (val) => setDialogState(() => selectedTable = val),
                        isExpanded: true,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: selectedTable == null ? null : () async {
                Navigator.pop(ctx);
                await _performTransfer(sourceTable.id, selectedTable!);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
              child: Text('نقل', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performTransfer(String sourceTableId, String targetTableNumber) async {
    try {
      await _tableRepository.transferOrder(
        sourceTableId: sourceTableId,
        targetTableNumber: targetTableNumber,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم نقل الطلب إلى طاولة #$targetTableNumber بنجاح')),
        );
        _fetchTables();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showAddTableDialog() {
    final numberController = TextEditingController();
    final capacityController = TextEditingController(text: '4');
    String selectedArea = 'صالة';
    final areas = ['صالة', 'تيراس', 'فيلا', 'خاصة'];

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2A2A3D),
          title: Text('إضافة طاولة جديدة', style: GoogleFonts.cairo(color: Colors.white)),
          content: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numberController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'رقم الطاولة',
                    labelStyle: GoogleFonts.cairo(color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0xFF1E1E2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'السعة',
                    labelStyle: GoogleFonts.cairo(color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0xFF1E1E2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedArea,
                      dropdownColor: const Color(0xFF1E1E2E),
                      items: areas.map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a, style: GoogleFonts.cairo(color: Colors.white)),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedArea = val!),
                      isExpanded: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (numberController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _tableRepository.createTable(
                    tableNumber: numberController.text.trim(),
                    capacity: int.tryParse(capacityController.text) ?? 4,
                    area: selectedArea,
                  );
                  _fetchTables();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إضافة الطاولة بنجاح')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
              child: Text('إضافة', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(TableModel table) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2A2A3D),
          title: Text('حذف طاولة #${table.tableNumber}', style: GoogleFonts.cairo(color: Colors.white)),
          content: Text('هل أنت متأكد من حذف هذه الطاولة؟', style: GoogleFonts.cairo(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _tableRepository.deleteTable(table.id);
                  _fetchTables();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حذف الطاولة')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                    );
                  }
                }
              },
              child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A2A3D),
          title: Text("طاولات الصالة 🍽️", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF6C5CE7)),
              onPressed: _showAddTableDialog,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchTables,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetchTables,
                icon: const Icon(Icons.refresh),
                label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
              )
            ],
          ),
        ),
      );
    }
    final grouped = <String, List<TableModel>>{};
    for (final t in _tables) {
      grouped.putIfAbsent(t.area, () => []).add(t);
    }

    return RefreshIndicator(
      onRefresh: _fetchTables,
      color: const Color(0xFF6C5CE7),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.place, color: const Color(0xFF6C5CE7), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      entry.key,
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF6C5CE7),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${entry.value.length})',
                      style: GoogleFonts.cairo(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: entry.value.length,
                itemBuilder: (context, index) {
                  final table = entry.value[index];
                  final color = _getTableColor(table.status);
                  return GestureDetector(
                    onTap: () => _showTableDetails(table),
                    onLongPress: () => _showDeleteConfirm(table),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3D),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color, width: 2),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8)],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Icon(Icons.table_restaurant, color: color, size: 32),
                              if (table.currentOrders.isNotEmpty)
                                Positioned(
                                  top: -4, right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${table.currentOrders.length}',
                                      style: GoogleFonts.cairo(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "طاولة #${table.tableNumber}",
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTableStatusText(table.status),
                              style: GoogleFonts.cairo(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (table.totalAmount > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${table.totalAmount.toStringAsFixed(0)} ج.م',
                              style: GoogleFonts.cairo(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }
}
