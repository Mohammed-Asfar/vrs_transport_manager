import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/core/utils/invoice_pdf_generator.dart';
import 'package:vrs_transport_manager/core/widgets/confirmation_dialog.dart';
import 'package:vrs_transport_manager/di/injection_container.dart';
import 'package:vrs_transport_manager/features/settings/domain/usecases/company_profile_usecases.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';
import 'package:vrs_transport_manager/features/invoice/domain/usecases/invoice_usecases.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/bloc/invoice_event.dart';

final _currencyFormat = NumberFormat('#,##,###.##', 'en_IN');

class InvoiceDetailPage extends StatefulWidget {
  final String recordId;

  const InvoiceDetailPage({super.key, required this.recordId});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  InvoiceRecord? _record;
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

    final result = await sl<GetInvoiceByIdUseCase>()(widget.recordId);
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
          Text('Invoice Details', style: AppTextStyles.heading3),
          const Spacer(),
          if (_record != null) ...[
            _toolbarButton(
              Icons.picture_as_pdf_rounded,
              'PDF',
              _generatePdf,
            ),
            const SizedBox(width: 4),
            _toolbarButton(
              Icons.edit_outlined,
              'Edit',
              () async {
                await context.push('/invoices/edit/${_record!.id}');
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
          _buildClientCard(record),
          const SizedBox(height: 20),
          ...record.sections.map((section) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildSectionTable(record, section),
            );
          }),
          _buildFinancialSummary(record),
        ],
      ),
    );
  }

  Widget _buildHeader(InvoiceRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/logo_512.png', width: 44, height: 44),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TAX INVOICE',
                    style: AppTextStyles.heading3
                        .copyWith(letterSpacing: 0.3)),
                Text(
                  record.invoiceNumber,
                  style: AppTextStyles.subtitle
                      .copyWith(color: AppColors.accent),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Invoice Date',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textTertiary)),
              Text(
                DateFormatter.toDisplay(record.invoiceDate),
                style:
                    AppTextStyles.subtitle.copyWith(color: AppColors.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(InvoiceRecord record) {
    final client = record.client;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Billed To',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 6),
          Text(client.companyName,
              style:
                  AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600)),
          if (client.gstin.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('GSTIN: ${client.gstin}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
          if (client.address.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(client.address,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTable(
      InvoiceRecord record, invoiceSection) {
    // Calculate the starting serial number for this section
    int startNo = 1;
    for (final s in record.sections) {
      if (identical(s, invoiceSection)) break;
      startNo += s.lineItems.length;
    }

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
            child: Text(
              invoiceSection.header.isNotEmpty
                  ? invoiceSection.header
                  : 'Line Items',
              style: AppTextStyles.heading3,
            ),
          ),
          const Divider(height: 0.5),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 16,
              headingRowHeight: 36,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 48,
              border: TableBorder(
                horizontalInside: BorderSide(
                    color: AppColors.separatorLight, width: 0.5),
              ),
              columns: const [
                DataColumn(label: Text('SL')),
                DataColumn(label: Text('SAC')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Unit')),
                DataColumn(label: Text('QTY'), numeric: true),
                DataColumn(label: Text('Rate'), numeric: true),
                DataColumn(label: Text('Amount'), numeric: true),
              ],
              rows: invoiceSection.lineItems.asMap().entries.map<DataRow>(
                (entry) {
                  final item = entry.value;
                  final sNo = startNo + entry.key;
                  return DataRow(cells: [
                    DataCell(Text('$sNo')),
                    DataCell(Text(item.sacCode)),
                    DataCell(SizedBox(
                      width: 200,
                      child: Text(item.description,
                          overflow: TextOverflow.ellipsis, maxLines: 2),
                    )),
                    DataCell(Text(item.unit)),
                    DataCell(Text(item.qty.toStringAsFixed(1))),
                    DataCell(Text(item.rate.toStringAsFixed(2))),
                    DataCell(Text(
                        '₹${_currencyFormat.format(item.totalAmount)}')),
                  ]);
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(InvoiceRecord record) {
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
            child: Column(
              children: [
                _row('Total Value',
                    '₹${_currencyFormat.format(record.totalValue)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 0.5),
                ),
                if (record.cgstPercent > 0)
                  _row(
                      'CGST @ ${record.cgstPercent.toStringAsFixed(0)}%',
                      '₹${_currencyFormat.format(record.cgstAmount)}'),
                if (record.sgstPercent > 0) ...[
                  const SizedBox(height: 4),
                  _row(
                      'SGST @ ${record.sgstPercent.toStringAsFixed(0)}%',
                      '₹${_currencyFormat.format(record.sgstAmount)}'),
                ],
                if (record.igstPercent > 0)
                  _row(
                      'IGST @ ${record.igstPercent.toStringAsFixed(0)}%',
                      '₹${_currencyFormat.format(record.igstAmount)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 0.5),
                ),
                _row('Sub Total',
                    '₹${_currencyFormat.format(record.subTotal)}',
                    isBold: true),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 0.5),
                ),
                if (record.tdsPercent > 0)
                  _row('TDS @ ${record.tdsPercent.toStringAsFixed(0)}%',
                      '- ₹${_currencyFormat.format(record.tdsAmount)}'),
                if (record.retentionPercent > 0) ...[
                  const SizedBox(height: 4),
                  _row(
                      'Retention @ ${record.retentionPercent.toStringAsFixed(0)}%',
                      '- ₹${_currencyFormat.format(record.retentionAmount)}'),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _row(
                  'Total Invoice Value',
                  '₹${_currencyFormat.format(record.totalInvoiceValue)}',
                  isBold: true,
                  valueColor: AppColors.accent,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record.amountInWords,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
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

  Widget _row(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600)
              : AppTextStyles.body,
        ),
        Text(
          value,
          style:
              (isBold ? AppTextStyles.heading3 : AppTextStyles.subtitle)
                  .copyWith(
            color: valueColor,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _generatePdf() async {
    final result = await sl<GetCompanyProfileUseCase>()();
    final profile = result.fold((_) => null, (p) => p);
    await InvoicePdfGenerator.generateAndPrint(_record!, profile);
  }

  Future<void> _deleteRecord() async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Invoice',
      message:
          'Are you sure you want to delete invoice ${_record!.invoiceNumber}?',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline_rounded,
    );
    if (confirm == true && mounted) {
      context
          .read<InvoiceBloc>()
          .add(InvoiceDeleteRecord(_record!.id!));
      context.pop();
    }
  }
}
