import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/features/payment/domain/entities/payment.dart';

class PaymentDialog extends StatefulWidget {
  final String transporterName;
  final double balance;
  final double totalPaid;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final String? createdBy;

  const PaymentDialog({
    super.key,
    required this.transporterName,
    required this.balance,
    required this.totalPaid,
    required this.weekStartDate,
    required this.weekEndDate,
    this.createdBy,
  });

  /// Shows the dialog and returns a Payment if the user confirms, null otherwise
  static Future<Payment?> show(
    BuildContext context, {
    required String transporterName,
    required double balance,
    required double totalPaid,
    required DateTime weekStartDate,
    required DateTime weekEndDate,
    String? createdBy,
  }) {
    return showDialog<Payment>(
      context: context,
      builder: (_) => PaymentDialog(
        transporterName: transporterName,
        balance: balance,
        totalPaid: totalPaid,
        weekStartDate: weekStartDate,
        weekEndDate: weekEndDate,
        createdBy: createdBy,
      ),
    );
  }

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  late DateTime _paymentDate;

  double get _remaining => widget.balance - widget.totalPaid;
  double get _amount => double.tryParse(_amountController.text) ?? 0;
  bool get _isOverpay => _amount + widget.totalPaid > widget.balance;

  @override
  void initState() {
    super.initState();
    _paymentDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final payment = Payment(
      transporterName: widget.transporterName,
      amount: _amount,
      paymentDate: _paymentDate,
      weekStartDate: widget.weekStartDate,
      weekEndDate: widget.weekEndDate,
      remarks: _remarksController.text.trim(),
      createdBy: widget.createdBy,
    );
    Navigator.of(context).pop(payment);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.separator, width: 0.5),
      ),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 20, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text('Record Payment', style: AppTextStyles.heading3),
                  ],
                ),
                const SizedBox(height: 20),

                // Info rows
                _infoRow('Transporter', widget.transporterName),
                const SizedBox(height: 8),
                _infoRow(
                  'Period',
                  '${DateFormatter.toDisplay(widget.weekStartDate)} – ${DateFormatter.toDisplay(widget.weekEndDate)}',
                ),
                const SizedBox(height: 8),
                _infoRow(
                  'Total Balance',
                  '₹${widget.balance.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 8),
                _infoRow(
                  'Already Paid',
                  '₹${widget.totalPaid.toStringAsFixed(0)}',
                  valueColor: widget.totalPaid > 0
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                _infoRow(
                  'Remaining',
                  '₹${_remaining.toStringAsFixed(0)}',
                  valueColor:
                      _remaining > 0 ? AppColors.warning : AppColors.success,
                ),

                const SizedBox(height: 20),
                const Divider(height: 0.5, color: AppColors.separator),
                const SizedBox(height: 20),

                // Amount field
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofocus: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter amount';
                    final amount = double.tryParse(v);
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Payment date
                GestureDetector(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Payment Date',
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 16),
                    ),
                    child: Text(
                      DateFormatter.toDisplay(_paymentDate),
                      style: AppTextStyles.body,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Remarks
                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (optional)',
                  ),
                  maxLines: 2,
                ),

                // Overpay warning
                if (_isOverpay && _amount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This will overpay by ₹${(_amount + widget.totalPaid - widget.balance).toStringAsFixed(0)}',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel',
                          style: AppTextStyles.button
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Record Payment'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTextStyles.subtitle.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            )),
      ],
    );
  }
}
