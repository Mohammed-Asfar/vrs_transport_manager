import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/core/widgets/confirmation_dialog.dart';
import 'package:vrs_transport_manager/di/injection_container.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/billing_mode.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/machinery_record.dart';
import 'package:vrs_transport_manager/core/utils/machinery_pdf_generator.dart';
import 'package:vrs_transport_manager/features/machinery/domain/usecases/machinery_usecases.dart';
import 'package:vrs_transport_manager/features/machinery/presentation/bloc/machinery_bloc.dart';
import 'package:vrs_transport_manager/features/machinery/presentation/bloc/machinery_event.dart';

class MachineryDetailPage extends StatefulWidget {
  final String recordId;

  const MachineryDetailPage({super.key, required this.recordId});

  @override
  State<MachineryDetailPage> createState() => _MachineryDetailPageState();
}

class _MachineryDetailPageState extends State<MachineryDetailPage> {
  MachineryRecord? _record;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result =
        await sl<GetMachineryRecordByIdUseCase>()(widget.recordId);
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isLoading = false;
      }),
      (record) => setState(() {
        _record = record;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.toolbar,
        border: Border(
          bottom: BorderSide(color: AppColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.accent),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 8),
          Text('Machinery Details', style: AppTextStyles.heading3),
          const Spacer(),
          if (_record != null) ...[
            _toolbarButton(
              Icons.picture_as_pdf_outlined,
              'PDF',
              () => MachineryPdfGenerator.generateAndPrint(_record!),
            ),
            const SizedBox(width: 4),
            _toolbarButton(
              Icons.edit_outlined,
              'Edit',
              () async {
                await context.push('/machinery/edit/${_record!.id}');
                _loadRecord();
              },
            ),
            const SizedBox(width: 4),
            _toolbarButton(
              Icons.delete_outline_rounded,
              'Delete',
              _deleteRecord,
              color: AppColors.error,
            ),
          ],
        ],
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String label, VoidCallback onPressed,
      {Color? color}) {
    return SizedBox(
      height: 28,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        label: Text(label,
            style: AppTextStyles.caption.copyWith(
                color: color ?? AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.accent),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 36, color: AppColors.error.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(_error!,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 28,
              child: OutlinedButton(
                  onPressed: _loadRecord, child: const Text('Retry')),
            ),
          ],
        ),
      );
    }

    final record = _record!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(record),
          const SizedBox(height: 20),
          _buildBillingDetails(record),
          const SizedBox(height: 20),
          _buildFinancialCard(record),
          if (record.remarks.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildRemarksCard(record),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(MachineryRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.construction_outlined,
                color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.machineName.toUpperCase(),
                    style:
                        AppTextStyles.heading3.copyWith(letterSpacing: 0.3)),
                if (record.machineNumber.isNotEmpty)
                  Text(
                    record.machineNumber,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                if (record.operatorName.isNotEmpty)
                  Text(
                    'Operator: ${record.operatorName}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                if (record.location.isNotEmpty)
                  Text(
                    record.location,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: record.billingMode == BillingMode.monthlyRent
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record.billingMode == BillingMode.monthlyRent
                      ? 'Monthly Rent'
                      : 'Per Load',
                  style: AppTextStyles.caption.copyWith(
                    color: record.billingMode == BillingMode.monthlyRent
                        ? AppColors.accent
                        : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (record.billingMode == BillingMode.monthlyRent &&
                  record.startDate != null &&
                  record.endDate != null)
                Text(
                  '${DateFormatter.toDisplay(record.startDate!)} - ${DateFormatter.toDisplay(record.endDate!)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.accent),
                )
              else
                Text(
                  DateFormatter.toDisplay(record.date),
                  style: AppTextStyles.subtitle
                      .copyWith(color: AppColors.accent),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingDetails(MachineryRecord record) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Text('Billing Details', style: AppTextStyles.heading3),
          ),
          const Divider(height: 0.5),
          Padding(
            padding: const EdgeInsets.all(16),
            child: record.billingMode == BillingMode.monthlyRent
                ? _buildMonthlyRentDetails(record)
                : _buildPerLoadDetails(record),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRentDetails(MachineryRecord record) {
    return Row(
      children: [
        _detailBox(
          'Monthly Rent',
          '₹${record.monthlyRent.toStringAsFixed(0)}',
          Icons.currency_rupee,
        ),
        const SizedBox(width: 16),
        _detailBox(
          'Period',
          record.startDate != null && record.endDate != null
              ? '${DateFormatter.toDisplay(record.startDate!)} - ${DateFormatter.toDisplay(record.endDate!)}'
              : 'Not specified',
          Icons.date_range_outlined,
        ),
      ],
    );
  }

  Widget _buildPerLoadDetails(MachineryRecord record) {
    return Row(
      children: [
        _detailBox(
          'Rate per Load',
          '₹${record.ratePerLoad.toStringAsFixed(0)}',
          Icons.currency_rupee,
        ),
        const SizedBox(width: 16),
        _detailBox(
          'Total Loads',
          '${record.totalLoads}',
          Icons.repeat,
        ),
        const SizedBox(width: 16),
        _detailBox(
          'Total Amount',
          '₹${record.totalAmount.toStringAsFixed(0)}',
          Icons.calculate_outlined,
          highlight: true,
        ),
      ],
    );
  }

  Widget _detailBox(String label, String value, IconData icon,
      {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.heading3.copyWith(
                color:
                    highlight ? AppColors.accent : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(MachineryRecord record) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Text('Financial Summary', style: AppTextStyles.heading3),
          ),
          const Divider(height: 0.5),
          Padding(
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.separator, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          _financialRow('Total Amount',
                              '₹${record.totalAmount.toStringAsFixed(0)}'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 0.5),
                          ),
                          _financialRow('Diesel',
                              '- ₹${record.diesel.toStringAsFixed(0)}',
                              color: AppColors.textSecondary),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 0.5),
                          ),
                          _financialRow('Advance',
                              '- ₹${record.advance.toStringAsFixed(0)}',
                              color: AppColors.textSecondary),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),
                          _financialRow(
                            'Balance',
                            '₹${record.balance.toStringAsFixed(0)}',
                            color: record.balance >= 0
                                ? AppColors.accent
                                : AppColors.error,
                            isBold: true,
                            isLarge: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.separator, width: 0.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _summaryItem('Advance',
                              '₹${record.advance.toStringAsFixed(0)}'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 0.5),
                          ),
                          _summaryItem(
                            'Balance',
                            '₹${record.balance.toStringAsFixed(0)}',
                            isLarge: true,
                            color: record.balance >= 0
                                ? AppColors.accent
                                : AppColors.error,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksCard(MachineryRecord record) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Remarks', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(record.remarks,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _financialRow(String label, String value,
      {Color? color, bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isLarge ? AppTextStyles.heading3 : AppTextStyles.body)
              .copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: (isLarge ? AppTextStyles.heading3 : AppTextStyles.body)
              .copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(String label, String value,
      {bool isLarge = false, Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style:
              (isLarge ? AppTextStyles.heading2 : AppTextStyles.heading3)
                  .copyWith(
            color: color ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteRecord() async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Record',
      message: 'Are you sure you want to delete this machinery record?',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline_rounded,
    );
    if (confirm == true && mounted) {
      context
          .read<MachineryBloc>()
          .add(MachineryDeleteRecord(_record!.id!));
      context.pop();
    }
  }
}
