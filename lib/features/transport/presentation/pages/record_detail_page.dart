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
              icon:
                  const Icon(Icons.arrow_back_rounded, color: AppColors.accent),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 8),
          Text('Record Details', style: AppTextStyles.heading3),
          const Spacer(),
          if (_record != null) ...[
            _toolbarButton(
              Icons.picture_as_pdf_rounded,
              'PDF',
              () => PdfGenerator.generateAndPrint(_record!),
            ),
            const SizedBox(width: 4),
            _toolbarButton(
              Icons.edit_outlined,
              'Edit',
              () async {
                await context.push('/edit/${_record!.id}');
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
          _buildCompanyHeader(record),
          const SizedBox(height: 20),
          _buildTripTable(record),
          const SizedBox(height: 20),
          _buildFinancialCard(record),
        ],
      ),
    );
  }

  Widget _buildCompanyHeader(TransportRecord record) {
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
                Text('VRS ENTERPRISES',
                    style:
                        AppTextStyles.heading3.copyWith(letterSpacing: 0.3)),
                Text(
                  record.location.toUpperCase(),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Date',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textTertiary)),
              Text(
                DateFormatter.toDisplay(record.date),
                style:
                    AppTextStyles.subtitle.copyWith(color: AppColors.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripTable(TransportRecord record) {
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
            child: Text('Trip Details', style: AppTextStyles.heading3),
          ),
          const Divider(height: 0.5),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 16,
              headingRowHeight: 36,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 42,
              border: TableBorder(
                horizontalInside:
                    BorderSide(color: AppColors.separatorLight, width: 0.5),
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
                    DataCell(
                        Text('₹${trip.amountPerTrip.toStringAsFixed(0)}')),
                    DataCell(Text('${trip.noOfLoads}')),
                  ]),
                ),
                // Total row
                DataRow(
                  color: WidgetStateProperty.all(AppColors.surfaceSecondary),
                  cells: [
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    DataCell(Text(
                      'Total',
                      style: AppTextStyles.tableHeader
                          .copyWith(color: AppColors.accent),
                    )),
                    DataCell(Text(
                      '${record.totalLoads}',
                      style: AppTextStyles.tableHeader
                          .copyWith(color: AppColors.accent),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(TransportRecord record) {
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount table
                Expanded(
                  flex: 2,
                  child: _buildAmountTable(record),
                ),
                const SizedBox(width: 24),
                // Summary
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: AppColors.separator, width: 0.5),
                    ),
                    child: Column(
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
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ],
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

  Widget _buildAmountTable(TransportRecord record) {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 12,
        headingRowHeight: 36,
        dataRowMinHeight: 34,
        dataRowMaxHeight: 40,
        border: TableBorder(
          horizontalInside:
              BorderSide(color: AppColors.separatorLight, width: 0.5),
          top: BorderSide(color: AppColors.separator, width: 0.5),
          bottom: BorderSide(color: AppColors.separator, width: 0.5),
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
          DataRow(
            color: WidgetStateProperty.all(AppColors.surfaceSecondary),
            cells: [
              DataCell(Text(
                '₹${record.totalAmount.toStringAsFixed(0)}',
                style: AppTextStyles.tableHeader
                    .copyWith(color: AppColors.accent),
              )),
              DataCell(Text(
                record.diesel.toStringAsFixed(0),
                style: AppTextStyles.tableHeader
                    .copyWith(color: AppColors.accent),
              )),
              DataCell(Text(
                '₹${record.totalAmount.toStringAsFixed(0)}',
                style: AppTextStyles.tableHeader
                    .copyWith(color: AppColors.accent),
              )),
            ],
          ),
        ],
      ),
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
      message: 'Are you sure you want to delete this record?',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline_rounded,
    );
    if (confirm == true && mounted) {
      context
          .read<TransportBloc>()
          .add(TransportDeleteRecord(_record!.id!));
      context.pop();
    }
  }
}
