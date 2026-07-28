import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../main.dart';
import '../../core/utils/zatca_qr.dart';

class CheckoutModal extends StatefulWidget {
  final double totalAmount;
  final double vatAmount;
  final String? sellerName;
  final String? vatNumber;
  final Function(String paymentMethod, double amountPaid) onPaymentConfirmed;

  const CheckoutModal({
    super.key,
    required this.totalAmount,
    this.vatAmount = 0,
    this.sellerName,
    this.vatNumber,
    required this.onPaymentConfirmed,
  });

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal> {
  String _selectedMethod = 'cash';
  late TextEditingController _amountPaidController;
  double _changeAmount = 0.0;
  bool _showReceiptPreview = false;

  @override
  void initState() {
    super.initState();
    _amountPaidController = TextEditingController(text: widget.totalAmount.toStringAsFixed(2));
    _calculateChange();
  }

  void _calculateChange() {
    final paid = double.tryParse(_amountPaidController.text) ?? widget.totalAmount;
    setState(() {
      _changeAmount = (paid - widget.totalAmount).clamp(0.0, double.infinity);
    });
  }

  Widget _buildPaymentTypeButton(String method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMethod = method;
            if (method == 'card') {
              _amountPaidController.text = widget.totalAmount.toStringAsFixed(2);
              _calculateChange();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCashButton(double amount) {
    return InkWell(
      onTap: () {
        _amountPaidController.text = amount.toStringAsFixed(2);
        _calculateChange();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Text(
          "${amount.toStringAsFixed(0)} ج.م",
          style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildReceiptView() {
    final sellerName = widget.sellerName ?? 'مطعم ومأكولات زمام';
    final vatNumber = widget.vatNumber ?? '300000000000003';
    final zatcaData = ZatcaQr.generate(
      sellerName: sellerName,
      vatNumber: vatNumber,
      timestamp: DateTime.now(),
      totalAmount: widget.totalAmount,
      vatAmount: widget.vatAmount,
    );
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(sellerName, style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              Text("فاتورة ضريبية مبسطة", style: GoogleFonts.cairo(color: Colors.black54, fontSize: 12)),
              if (vatNumber.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text("الرقم الضريبي: $vatNumber", style: GoogleFonts.cairo(color: Colors.black54, fontSize: 11)),
              ],
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("إجمالي الفاتورة (شامل الضريبة):", style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text("${widget.totalAmount.toStringAsFixed(2)} ج.م", style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              if (widget.vatAmount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ضريبة القيمة المضافة:", style: GoogleFonts.cairo(color: Colors.black54, fontSize: 12)),
                    Text("${widget.vatAmount.toStringAsFixed(2)} ج.م", style: GoogleFonts.cairo(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              QrImageView(
                data: zatcaData,
                version: QrVersions.auto,
                size: 140.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 4),
              Text("QR Code ضريبي (ZATCA)", style: GoogleFonts.cairo(color: Colors.black38, fontSize: 10)),
              const SizedBox(height: 8),
              Text("شكراً لزيارتكم! 🙏", style: GoogleFonts.cairo(color: Colors.black87, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              final paid = double.tryParse(_amountPaidController.text) ?? widget.totalAmount;
              widget.onPaymentConfirmed(_selectedMethod, paid);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            icon: const Icon(Icons.print, color: Colors.white),
            label: Text("طباعة الفاتورة وإتمام الطلب ✅", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.credit_card, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        "إتمام عملية الدفع",
                        style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF9E9E9E)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              if (_showReceiptPreview) ...[
                _buildReceiptView(),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("المبلغ المطلوب للدفع:", style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 14)),
                      Text(
                        "${widget.totalAmount.toStringAsFixed(2)} ج.م",
                        style: GoogleFonts.cairo(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text("اختر طريقة الدفع:", style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildPaymentTypeButton('cash', 'نقدي (Cash)', Icons.money),
                    const SizedBox(width: 10),
                    _buildPaymentTypeButton('card', 'بطاقة (Card)', Icons.credit_card),
                  ],
                ),
                const SizedBox(height: 20),
                if (_selectedMethod == 'cash') ...[
                  Text("المبلغ المدفوع من الزبون:", style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountPaidController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    onChanged: (_) => _calculateChange(),
                    decoration: const InputDecoration(
                      suffixText: "ج.م",
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickCashButton(widget.totalAmount),
                      _buildQuickCashButton(50),
                      _buildQuickCashButton(100),
                      _buildQuickCashButton(200),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("الباقي للزبون:", style: GoogleFonts.cairo(color: AppColors.success, fontWeight: FontWeight.bold)),
                        Text(
                          "${_changeAmount.toStringAsFixed(2)} ج.م",
                          style: GoogleFonts.cairo(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showReceiptPreview = true;
                      });
                    },
                    child: Text(
                      "تأكيد وحفظ الفاتورة 🧾",
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
