import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/core/widgets/app_text_field.dart';
import 'package:vrs_transport_manager/core/widgets/loading_overlay.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/trip_entry.dart';
import 'package:vrs_transport_manager/features/transport/presentation/bloc/transport_bloc.dart';
import 'package:vrs_transport_manager/features/transport/presentation/bloc/transport_event.dart';
import 'package:vrs_transport_manager/features/transport/presentation/bloc/transport_state.dart';
import 'package:vrs_transport_manager/di/injection_container.dart';

import 'package:vrs_transport_manager/features/auth/domain/repositories/auth_repository.dart';

class RecordFormPage extends StatefulWidget {
  final TransportRecord? existingRecord;

  const RecordFormPage({super.key, this.existingRecord});

  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late TextEditingController _locationController;
  late TextEditingController _dieselController;
  late TextEditingController _advanceController;
  late List<_TripFormData> _trips;

  bool get _isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;
    _selectedDate = record?.date ?? DateTime.now();
    _locationController = TextEditingController(text: record?.location ?? 'Madayampakkam');
    _dieselController = TextEditingController(text: record?.diesel.toString() ?? '0');
    _advanceController = TextEditingController(text: record?.advance.toString() ?? '0');

    if (record != null && record.trips.isNotEmpty) {
      _trips = record.trips
          .map((t) => _TripFormData(
                vehicleNo: TextEditingController(text: t.vehicleNo),
                transporter: TextEditingController(text: t.transporter),
                chainage: TextEditingController(text: t.chainage.toString()),
                km: TextEditingController(text: t.km.toString()),
                ratePerKm: TextEditingController(text: t.ratePerKm.toString()),
                noOfLoads: TextEditingController(text: t.noOfLoads.toString()),
              ))
          .toList();
    } else {
      _trips = [_TripFormData.empty()];
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _dieselController.dispose();
    _advanceController.dispose();
    for (final trip in _trips) {
      trip.dispose();
    }
    super.dispose();
  }

  void _addTrip() {
    setState(() {
      _trips.add(_TripFormData.empty());
    });
  }

  void _removeTrip(int index) {
    if (_trips.length > 1) {
      setState(() {
        _trips[index].dispose();
        _trips.removeAt(index);
      });
    }
  }

  double _calculateTripAmount(int index) {
    final km = double.tryParse(_trips[index].km.text) ?? 0;
    final rate = double.tryParse(_trips[index].ratePerKm.text) ?? 0;
    return km * rate;
  }

  int get _totalLoads {
    return _trips.fold(0, (sum, t) => sum + (int.tryParse(t.noOfLoads.text) ?? 0));
  }

  double get _totalAmount {
    double total = 0;
    for (int i = 0; i < _trips.length; i++) {
      final loads = int.tryParse(_trips[i].noOfLoads.text) ?? 0;
      total += _calculateTripAmount(i) * loads;
    }
    return total;
  }

  double get _diesel => double.tryParse(_dieselController.text) ?? 0;
  double get _advance => double.tryParse(_advanceController.text) ?? 0;
  double get _balance => _totalAmount - _diesel - _advance;

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final trips = <TripEntry>[];
    for (int i = 0; i < _trips.length; i++) {
      trips.add(TripEntry.create(
        sNo: i + 1,
        vehicleNo: _trips[i].vehicleNo.text.trim(),
        transporter: _trips[i].transporter.text.trim(),
        chainage: double.tryParse(_trips[i].chainage.text) ?? 0,
        km: double.tryParse(_trips[i].km.text) ?? 0,
        ratePerKm: double.tryParse(_trips[i].ratePerKm.text) ?? 0,
        noOfLoads: int.tryParse(_trips[i].noOfLoads.text) ?? 0,
      ));
    }

    final currentUser = sl<AuthRepository>().currentUser;

    final record = TransportRecord.create(
      id: widget.existingRecord?.id,
      date: _selectedDate,
      location: _locationController.text.trim(),
      trips: trips,
      diesel: _diesel,
      advance: _advance,
      createdBy: currentUser?.uid,
    );

    if (_isEditing) {
      context.read<TransportBloc>().add(TransportUpdateRecord(record));
    } else {
      context.read<TransportBloc>().add(TransportCreateRecord(record));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransportBloc, TransportState>(
      listener: (context, state) {
        if (state is TransportOperationSuccess) {
          context.pop();
        }
        if (state is TransportError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) => LoadingOverlay(
        isLoading: state is TransportLoading,
        message: _isEditing ? 'Updating record...' : 'Saving record...',
        child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Record' : 'New Transport Record'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: _onSave,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(_isEditing ? 'Update' : 'Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info Card
                _buildHeaderCard(),
                const SizedBox(height: 24),

                // Trip entries
                _buildTripsSection(),
                const SizedBox(height: 24),

                // Financial Summary
                _buildFinancialSummary(),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeaderCard() {
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
            Text('Record Details', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _locationController,
                    label: 'Location',
                    prefixIcon: Icons.location_on_outlined,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Location is required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Date',
                    readOnly: true,
                    prefixIcon: Icons.calendar_today_outlined,
                    controller: TextEditingController(
                      text: DateFormatter.toDisplay(_selectedDate),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsSection() {
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
            Row(
              children: [
                Text('Trip Entries', style: AppTextStyles.heading3),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addTrip,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Trip'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Trip entries data table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _headerCell('S.No', flex: 1),
                  _headerCell('Vehicle No', flex: 3),
                  _headerCell('Transporter', flex: 2),
                  _headerCell('Chainage', flex: 2),
                  _headerCell('KM', flex: 2),
                  _headerCell('Rate/KM', flex: 2),
                  _headerCell('Amount', flex: 2),
                  _headerCell('Loads', flex: 2),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Trip rows
            ...List.generate(_trips.length, (index) => _buildTripRow(index)),

            const SizedBox(height: 12),
            // Totals row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Expanded(flex: 12, child: SizedBox()),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${_totalAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$_totalLoads',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: AppTextStyles.tableHeader),
    );
  }

  Widget _buildTripRow(int index) {
    final trip = _trips[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // S.No
            Expanded(
              flex: 1,
              child: Text(
                '${index + 1}',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            // Vehicle No
            Expanded(
              flex: 3,
              child: _rowField(trip.vehicleNo, 'Vehicle No',
                  validator: (v) => v?.isEmpty == true ? 'Required' : null),
            ),
            // Transporter
            Expanded(
              flex: 2,
              child: _rowField(trip.transporter, 'Transporter',
                  validator: (v) => v?.isEmpty == true ? 'Required' : null),
            ),
            // Chainage
            Expanded(
              flex: 2,
              child: _rowField(trip.chainage, 'Chainage', isNumber: true),
            ),
            // KM
            Expanded(
              flex: 2,
              child: _rowField(trip.km, 'KM', isNumber: true, onChanged: (_) => setState(() {})),
            ),
            // Rate/KM
            Expanded(
              flex: 2,
              child: _rowField(trip.ratePerKm, 'Rate', isNumber: true, onChanged: (_) => setState(() {})),
            ),
            // Amount (calculated)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₹${_calculateTripAmount(index).toStringAsFixed(0)}',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            // No of Loads
            Expanded(
              flex: 2,
              child: _rowField(trip.noOfLoads, 'Loads', isNumber: true, onChanged: (_) => setState(() {})),
            ),
            // Delete button
            SizedBox(
              width: 40,
              child: _trips.length > 1
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                      onPressed: () => _removeTrip(index),
                      tooltip: 'Remove trip',
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: validator,
        onChanged: onChanged,
        style: AppTextStyles.tableCell,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.tableCell.copyWith(color: AppColors.textHint),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.background,
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
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
            Text('Financial Summary', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _dieselController,
                    label: 'Diesel',
                    prefixIcon: Icons.local_gas_station_outlined,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _advanceController,
                    label: 'Advance',
                    prefixIcon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _summaryRow('Total Amount', '₹${_totalAmount.toStringAsFixed(0)}'),
                  const Divider(height: 20),
                  _summaryRow('Diesel', '- ₹${_diesel.toStringAsFixed(0)}'),
                  const Divider(height: 20),
                  _summaryRow('Advance', '- ₹${_advance.toStringAsFixed(0)}'),
                  const Divider(height: 20),
                  _summaryRow(
                    'Balance',
                    '₹${_balance.toStringAsFixed(0)}',
                    isBold: true,
                    valueColor: _balance >= 0 ? AppColors.success : AppColors.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)
              : AppTextStyles.body,
        ),
        Text(
          value,
          style: (isBold ? AppTextStyles.heading3 : AppTextStyles.subtitle).copyWith(
            color: valueColor,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TripFormData {
  final TextEditingController vehicleNo;
  final TextEditingController transporter;
  final TextEditingController chainage;
  final TextEditingController km;
  final TextEditingController ratePerKm;
  final TextEditingController noOfLoads;

  _TripFormData({
    required this.vehicleNo,
    required this.transporter,
    required this.chainage,
    required this.km,
    required this.ratePerKm,
    required this.noOfLoads,
  });

  factory _TripFormData.empty() {
    return _TripFormData(
      vehicleNo: TextEditingController(),
      transporter: TextEditingController(),
      chainage: TextEditingController(),
      km: TextEditingController(),
      ratePerKm: TextEditingController(),
      noOfLoads: TextEditingController(text: '1'),
    );
  }

  void dispose() {
    vehicleNo.dispose();
    transporter.dispose();
    chainage.dispose();
    km.dispose();
    ratePerKm.dispose();
    noOfLoads.dispose();
  }
}
