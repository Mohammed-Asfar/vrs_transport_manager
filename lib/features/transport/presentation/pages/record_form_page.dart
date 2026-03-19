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
  late TextEditingController _transporterController;
  late TextEditingController _dieselController;
  late TextEditingController _advanceController;
  late List<_TripFormData> _trips;

  bool get _isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;
    _selectedDate = record?.date ?? DateTime.now();
    _locationController =
        TextEditingController(text: record?.location ?? 'Madayampakkam');
    _transporterController =
        TextEditingController(text: record?.transporter ?? '');
    _dieselController =
        TextEditingController(text: record?.diesel.toString() ?? '0');
    _advanceController =
        TextEditingController(text: record?.advance.toString() ?? '0');

    if (record != null && record.trips.isNotEmpty) {
      _trips = record.trips
          .map((t) => _TripFormData(
                vehicleNo: TextEditingController(text: t.vehicleNo),
                chainage:
                    TextEditingController(text: t.chainage.toString()),
                km: TextEditingController(text: t.km.toString()),
                ratePerKm:
                    TextEditingController(text: t.ratePerKm.toString()),
                noOfLoads:
                    TextEditingController(text: t.noOfLoads.toString()),
              ))
          .toList();
    } else {
      _trips = [_TripFormData.empty()];
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _transporterController.dispose();
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
    return _trips.fold(
        0, (sum, t) => sum + (int.tryParse(t.noOfLoads.text) ?? 0));
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
      transporter: _transporterController.text.trim(),
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
            ),
          );
        }
      },
      builder: (context, state) => LoadingOverlay(
        isLoading: state is TransportLoading,
        message: _isEditing ? 'Updating record...' : 'Saving record...',
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Toolbar
              _buildToolbar(),

              // Form body
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSection(),
                        const SizedBox(height: 20),
                        _buildTripsSection(),
                        const SizedBox(height: 20),
                        _buildFinancialSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
          // Back
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
          Text(
            _isEditing ? 'Edit Record' : 'New Record',
            style: AppTextStyles.heading3,
          ),
          const Spacer(),
          SizedBox(
            height: 28,
            child: ElevatedButton.icon(
              onPressed: _onSave,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text(_isEditing ? 'Update' : 'Save'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return _MacSection(
      title: 'Record Details',
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: AppTextField(
              controller: _transporterController,
              label: 'Transporter',
              prefixIcon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Transporter is required' : null,
            ),
          ),
          const SizedBox(width: 12),
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
    );
  }

  Widget _buildTripsSection() {
    return _MacSection(
      title: 'Trip Entries',
      trailing: SizedBox(
        height: 26,
        child: ElevatedButton.icon(
          onPressed: _addTrip,
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Add Trip'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              border: Border(
                bottom: BorderSide(color: AppColors.separator, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                _headerCell('#', flex: 1),
                _headerCell('Vehicle No', flex: 3),
                _headerCell('Chainage', flex: 2),
                _headerCell('KM', flex: 2),
                _headerCell('Rate/KM', flex: 2),
                _headerCell('Amount', flex: 2),
                _headerCell('Loads', flex: 2),
                const SizedBox(width: 32),
              ],
            ),
          ),

          // Trip rows
          ...List.generate(_trips.length, (i) => _buildTripRow(i)),

          // Totals
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              border: Border(
                top: BorderSide(color: AppColors.separator, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Expanded(flex: 1, child: SizedBox()),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Total',
                    style: AppTextStyles.tableCell.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(flex: 6, child: SizedBox()),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${_totalAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.tableCell.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '$_totalLoads',
                    style: AppTextStyles.tableCell.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.separatorLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '${index + 1}',
              style: AppTextStyles.tableCell
                  .copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
              flex: 3,
              child: _rowField(trip.vehicleNo, 'Vehicle No',
                  validator: (v) => v?.isEmpty == true ? 'Required' : null)),
          Expanded(
              flex: 2,
              child: _rowField(trip.chainage, 'Chainage', isNumber: true)),
          Expanded(
              flex: 2,
              child: _rowField(trip.km, 'KM',
                  isNumber: true, onChanged: (_) => setState(() {}))),
          Expanded(
              flex: 2,
              child: _rowField(trip.ratePerKm, 'Rate',
                  isNumber: true, onChanged: (_) => setState(() {}))),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '₹${_calculateTripAmount(index).toStringAsFixed(0)}',
                style: AppTextStyles.tableCell
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
              flex: 2,
              child: _rowField(trip.noOfLoads, 'Loads',
                  isNumber: true, onChanged: (_) => setState(() {}))),
          SizedBox(
            width: 32,
            child: _trips.length > 1
                ? IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.error, size: 16),
                    onPressed: () => _removeTrip(index),
                    tooltip: 'Remove trip',
                  )
                : null,
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: validator,
        onChanged: onChanged,
        style: AppTextStyles.tableCell,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTextStyles.tableCell.copyWith(color: AppColors.textTertiary),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.background,
        ),
      ),
    );
  }

  Widget _buildFinancialSection() {
    return _MacSection(
      title: 'Financial Summary',
      child: Column(
        children: [
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.separator, width: 0.5),
            ),
            child: Column(
              children: [
                _summaryRow('Total Amount',
                    '₹${_totalAmount.toStringAsFixed(0)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 0.5),
                ),
                _summaryRow(
                    'Diesel', '- ₹${_diesel.toStringAsFixed(0)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 0.5),
                ),
                _summaryRow(
                    'Advance', '- ₹${_advance.toStringAsFixed(0)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 0.5),
                ),
                _summaryRow(
                  'Balance',
                  '₹${_balance.toStringAsFixed(0)}',
                  isBold: true,
                  valueColor:
                      _balance >= 0 ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
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
          style: (isBold ? AppTextStyles.heading3 : AppTextStyles.subtitle)
              .copyWith(
            color: valueColor,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// macOS-style section container with thin border and title.
class _MacSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _MacSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                Text(title, style: AppTextStyles.heading3),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
          ),
          const Divider(height: 0.5),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _TripFormData {
  final TextEditingController vehicleNo;
  final TextEditingController chainage;
  final TextEditingController km;
  final TextEditingController ratePerKm;
  final TextEditingController noOfLoads;

  _TripFormData({
    required this.vehicleNo,
    required this.chainage,
    required this.km,
    required this.ratePerKm,
    required this.noOfLoads,
  });

  factory _TripFormData.empty() {
    return _TripFormData(
      vehicleNo: TextEditingController(),
      chainage: TextEditingController(),
      km: TextEditingController(),
      ratePerKm: TextEditingController(),
      noOfLoads: TextEditingController(text: '1'),
    );
  }

  void dispose() {
    vehicleNo.dispose();
    chainage.dispose();
    km.dispose();
    ratePerKm.dispose();
    noOfLoads.dispose();
  }
}
