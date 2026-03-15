import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/core/utils/pdf_generator.dart';
import 'package:vrs_transport_manager/core/widgets/confirmation_dialog.dart';
import 'package:vrs_transport_manager/di/injection_container.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';
import 'package:vrs_transport_manager/features/transport/domain/usecases/transport_usecases.dart';
import 'package:vrs_transport_manager/features/transport/presentation/bloc/transport_bloc.dart';
import 'package:vrs_transport_manager/features/transport/presentation/bloc/transport_event.dart';

class RecordDetailPage extends StatefulWidget {
  final String recordId;

  const RecordDetailPage({super.key, required this.recordId});

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  TransportRecord? _record;
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

    final result = await sl<GetRecordByIdUseCase>()(widget.recordId);
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
      appBar: AppBar(
        title: const Text('Record Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_record != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Download PDF',
              onPressed: () => PdfGenerator.generateAndPrint(_record!),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit',
              onPressed: () async {
                await context.push('/edit/${_record!.id}');
                _loadRecord();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded),
              tooltip: 'Delete',
              onPressed: _deleteRecord,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(_error!, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadRecord, child: const Text('Retry')),
          ],
        ),
      );
    }

    final record = _record!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Header
          _buildCompanyHeader(record),
          const SizedBox(height: 24),

          // Trip Details Table
          _buildTripTable(record),
          const SizedBox(height: 24),

          // Financial Summary
          _buildFinancialCard(record),
        ],
      ),
    );
  }

  Widget _buildCompanyHeader(TransportRecord record) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VRS ENTERPRISES', style: AppTextStyles.heading2),
                  Text(
                    record.location.toUpperCase(),
                    style: AppTextStyles.subtitle.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Date',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                ),
                Text(
                  DateFormatter.toDisplay(record.date),
                  style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTable(TransportRecord record) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trip Details', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 44,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 48,
                border: TableBorder(
                  horizontalInside: BorderSide(color: AppColors.divider),
                  top: BorderSide(color: AppColors.border),
                  bottom: BorderSide(color: AppColors.border),
                ),
                columns: const [
                  DataColumn(label: Text('S.No')),
                  DataColumn(label: Text('Vehicle No')),
                  DataColumn(label: Text('Transporter')),
                  DataColumn(label: Text('Chainage'), numeric: true),
                  DataColumn(label: Text('KM'), numeric: true),
                  DataColumn(label: Text('Rate/KM'), numeric: true),
                  DataColumn(label: Text('Amount'), numeric: true),
                  DataColumn(label: Text('Loads'), numeric: true),
                ],
                rows: [
                  ...record.trips.map(
                    (trip) => DataRow(cells: [
                      DataCell(Text('${trip.sNo}')),
                      DataCell(Text(trip.vehicleNo)),
                      DataCell(Text(trip.transporter)),
                      DataCell(Text(trip.chainage.toStringAsFixed(0))),
                      DataCell(Text(trip.km.toStringAsFixed(0))),
                      DataCell(Text(trip.ratePerKm.toStringAsFixed(0))),
                      DataCell(Text('₹${trip.amountPerTrip.toStringAsFixed(0)}')),
                      DataCell(Text('${trip.noOfLoads}')),
                    ]),
                  ),
                  // Total row
                  DataRow(
                    color: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.05)),
                    cells: [
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      DataCell(Text(
                        'Total',
                        style: AppTextStyles.tableHeader.copyWith(
                          color: AppColors.primary,
                        ),
                      )),
                      DataCell(Text(
                        '${record.totalLoads}',
                        style: AppTextStyles.tableHeader.copyWith(
                          color: AppColors.primary,
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(TransportRecord record) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount breakdown
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Financial Summary', style: AppTextStyles.heading3),
                  const SizedBox(height: 20),
                  _buildAmountTable(record),
                ],
              ),
            ),
            const SizedBox(width: 40),

            // Summary totals
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _summaryItem('Advance', '₹${record.advance.toStringAsFixed(0)}'),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _summaryItem(
                      'Balance',
                      '₹${record.balance.toStringAsFixed(0)}',
                      isLarge: true,
                      color: record.balance >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountTable(TransportRecord record) {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        columnSpacing: 24,
        headingRowHeight: 44,
        border: TableBorder(
          horizontalInside: BorderSide(color: AppColors.divider),
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
        columns: const [
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Diesel')),
          DataColumn(label: Text('Balance')),
        ],
        rows: [
          ...record.trips.map((trip) {
            final tripTotal = trip.amountPerTrip * trip.noOfLoads;
            return DataRow(cells: [
              DataCell(Text('₹${tripTotal.toStringAsFixed(0)}')),
              const DataCell(Text('')),
              DataCell(Text('₹${tripTotal.toStringAsFixed(0)}')),
            ]);
          }),
          // Totals
          DataRow(
            color: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.05)),
            cells: [
              DataCell(Text(
                '₹${record.totalAmount.toStringAsFixed(0)}',
                style: AppTextStyles.tableHeader.copyWith(color: AppColors.primary),
              )),
              DataCell(Text(
                record.diesel.toStringAsFixed(0),
                style: AppTextStyles.tableHeader.copyWith(color: AppColors.primary),
              )),
              DataCell(Text(
                '₹${record.totalAmount.toStringAsFixed(0)}',
                style: AppTextStyles.tableHeader.copyWith(color: AppColors.primary),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, {bool isLarge = false, Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: (isLarge ? AppTextStyles.heading2 : AppTextStyles.heading3).copyWith(
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
      message: 'Are you sure you want to delete this record?',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline_rounded,
    );
    if (confirm == true && mounted) {
      context.read<TransportBloc>().add(TransportDeleteRecord(_record!.id!));
      context.pop();
    }
  }
}
