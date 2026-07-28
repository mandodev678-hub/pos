import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/shift_provider.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final TextEditingController _openingController = TextEditingController(text: '100.0');
  final TextEditingController _closingController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShiftProvider>().checkCurrentShift();
    });
  }

  @override
  void dispose() {
    _openingController.dispose();
    _closingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showCloseSummary(BuildContext context, Map<String, dynamic> summary) {
    final sum = summary['summary'] as Map<String, dynamic>?;
    final expected = (sum?['expected'] as num?)?.toDouble() ?? 0;
    final actual = (sum?['actual'] as num?)?.toDouble() ?? 0;
    final difference = (sum?['difference'] as num?)?.toDouble() ?? 0;
    final cashSales = (sum?['cash_sales'] as num?)?.toDouble() ?? 0;
    final cardSales = (sum?['card_sales'] as num?)?.toDouble() ?? 0;
    final orderCount = (sum?['order_count'] as num?)?.toInt() ?? 0;

    final isBalanced = difference == 0;
    final isExcess = difference > 0;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2A2A3D),
          title: Row(
            children: [
              Icon(
                isBalanced ? Icons.check_circle : (isExcess ? Icons.warning_amber : Icons.error),
                color: isBalanced ? Colors.greenAccent : (isExcess ? Colors.orangeAccent : Colors.redAccent),
              ),
              const SizedBox(width: 8),
              Text(
                isBalanced ? 'الوردية متوازنة ✅' : (isExcess ? 'زيادة في الصندوق' : 'عجز في الصندوق'),
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _summaryRow('عدد الطلبات', '$orderCount طلب'),
              _summaryRow('مبيعات نقدية', '${cashSales.toStringAsFixed(2)} ج.م'),
              _summaryRow('مبيعات بطاقة', '${cardSales.toStringAsFixed(2)} ج.م'),
              const Divider(color: Colors.white24),
              _summaryRow('المتوقع', '${expected.toStringAsFixed(2)} ج.م'),
              _summaryRow('الفعلي', '${actual.toStringAsFixed(2)} ج.م'),
              const Divider(color: Colors.white24),
              _summaryRow(
                isBalanced ? 'الفرق' : (isExcess ? 'الزيادة' : 'العجز'),
                '${difference.abs().toStringAsFixed(2)} ج.م',
                valueColor: isBalanced ? Colors.greenAccent : (isExcess ? Colors.orangeAccent : Colors.redAccent),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
              child: Text('تم', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
          Text(value,
            style: GoogleFonts.cairo(
              color: valueColor ?? Colors.amberAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shiftProvider = context.watch<ShiftProvider>();
    final hasShift = shiftProvider.hasActiveShift;
    final shift = shiftProvider.currentShift;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A2A3D),
          title: Text("إدارة الوردية (الخزينة)", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        ),
        body: shiftProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3D),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasShift ? Icons.check_circle : Icons.warning_amber_rounded,
                              color: hasShift ? Colors.greenAccent : Colors.orangeAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              hasShift ? "الوردية مفتوحة حالياً" : "لا يوجد وردية مفتوحة",
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 30),
                        if (!hasShift) ...[
                          Text(
                            "مبلغ بداية الوردية (العهدة النقودية):",
                            style: GoogleFonts.cairo(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _openingController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              suffixText: "ج.م",
                              suffixStyle: GoogleFonts.cairo(color: Colors.amberAccent),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF6C5CE7)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final amount = double.tryParse(_openingController.text) ?? 0.0;
                                await shiftProvider.openShift(amount);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم فتح الوردية بنجاح 🟢')),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              icon: const Icon(Icons.lock_open, color: Colors.white),
                              label: Text("فتح وردية جديدة", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else ...[
                          _summaryRow("مبلغ بداية الفتح:", "${shift!.startingCash.toStringAsFixed(2)} ج.م"),
                          const SizedBox(height: 8),
                          _summaryRow("وقت الفتح:", "${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')}"),
                          if (shift.cashSales != null) ...[
                            const SizedBox(height: 8),
                            _summaryRow("مبيعات نقدية:", "${shift.cashSales!.toStringAsFixed(2)} ج.م"),
                          ],
                          if (shift.cardSales != null) ...[
                            const SizedBox(height: 8),
                            _summaryRow("مبيعات بطاقة:", "${shift.cardSales!.toStringAsFixed(2)} ج.م"),
                          ],
                          if (shift.orderCount != null) ...[
                            const SizedBox(height: 8),
                            _summaryRow("عدد الطلبات:", "${shift.orderCount}"),
                          ],
                          const SizedBox(height: 20),
                          Text("المبلغ الفعلي بالدرج عند الإغلاق:", style: GoogleFonts.cairo(color: Colors.white70)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _closingController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "أدخل النقدية الفعلية",
                              hintStyle: GoogleFonts.cairo(color: Colors.white38),
                              suffixText: "ج.م",
                              suffixStyle: GoogleFonts.cairo(color: Colors.amberAccent),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF6C5CE7)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notesController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "ملاحظات الإغلاق (اختياري)",
                              hintStyle: GoogleFonts.cairo(color: Colors.white38),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF6C5CE7)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final closingAmount = double.tryParse(_closingController.text);
                                if (closingAmount == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('الرجاء إدخال المبلغ الفعلي')),
                                  );
                                  return;
                                }
                                try {
                                  final summary = await shiftProvider.closeShift(closingAmount, _notesController.text);
                                  if (!context.mounted) return;
                                  _showCloseSummary(context, summary);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$e')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              icon: const Icon(Icons.lock, color: Colors.white),
                              label: Text("إغلاق الوردية وحساب العجز/الزيادة", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
