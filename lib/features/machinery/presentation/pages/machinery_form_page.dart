import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/core/widgets/app_text_field.dart';
import 'package:vrs_transport_manager/core/widgets/loading_overlay.dart';
import 'package:vrs_transport_manager/di/injection_container.dart';
import 'package:vrs_transport_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/billing_mode.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/machinery_record.dart';
import 'package:vrs_transport_manager/features/machinery/presentation/bloc/machinery_bloc.dart';
import 'package:vrs_transport_manager/features/machinery/presentation/bloc/machinery_event.dart';
import 'package:vrs_transport_manager/features/machinery/presentation/bloc/machinery_state.dart';
import 'package:vrs_transport_manager/features/machinery/presentation/widgets/billing_mode_selector.dart';

class MachineryFormPage extends StatefulWidget {
  final MachineryRecord? existingRecord;

  const MachineryFormPage({super.key, this.existingRecord});

  @override
  State<MachineryFormPage> createState() => _MachineryFormPageState();
}

class _MachineryFormPageState extends State<MachineryFormPage> {
  final _formKey = GlobalKey<FormState>();

  late BillingMode _billingMode;
  late DateTime _selectedDate;
  DateTime? _startDate;
  DateTime? _endDate;
  late TextEditingController _machineNameController;
  late TextEditingController _machineNumberController;
  late TextEditingController _operatorNameController;
  late TextEditingController _locationController;
  late TextEditingController _monthlyRentController;
  late TextEditingController _ratePerLoadController;
  late TextEditingController _totalLoadsController;
  late TextEditingController _dieselController;
  late TextEditingController _advanceController;
  late TextEditingController _remarksController;

  bool get _isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;
    _billingMode = record?.billingMode ?? BillingMode.perLoad;
    _selectedDate = record?.date ?? DateTime.now();
    _startDate = record?.startDate;
    _endDate = record?.endDate;
    _machineNameController =
        TextEditingController(text: record?.machineName ?? '');
    _machineNumberController =
        TextEditingController(text: record?.machineNumber ?? '');
    _operatorNameController =
        TextEditingController(text: record?.operatorName ?? '');
    _locationController =
        TextEditingController(text: record?.location ?? '');
    _monthlyRentController =
        TextEditingController(text: record?.monthlyRent.toString() ?? '0');
    _ratePerLoadController =
        TextEditingController(text: record?.ratePerLoad.toString() ?? '0');
    _totalLoadsController =
        TextEditingController(text: record?.totalLoads.toString() ?? '0');
    _dieselController =
        TextEditingController(text: record?.diesel.toString() ?? '0');
    _advanceController =
        TextEditingController(text: record?.advance.toString() ?? '0');
    _remarksController =
        TextEditingController(text: record?.remarks ?? '');
  }

  @override
  void dispose() {
    _machineNameController.dispose();
    _machineNumberController.dispose();
    _operatorNameController.dispose();
    _locationController.dispose();
    _monthlyRentController.dispose();
    _ratePerLoadController.dispose();
    _totalLoadsController.dispose();
    _dieselController.dispose();
    _advanceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    if (_billingMode == BillingMode.monthlyRent) {
      return double.tryParse(_monthlyRentController.text) ?? 0;
    }
    final rate = double.tryParse(_ratePerLoadController.text) ?? 0;
    final loads = int.tryParse(_totalLoadsController.text) ?? 0;
    return rate * loads;
  }

  double get _diesel => double.tryParse(_dieselController.text) ?? 0;
  double get _advance => double.tryParse(_advanceController.text) ?? 0;
  double get _balance => _totalAmount - _advance;

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currentUser = sl<AuthRepository>().currentUser;

    final record = MachineryRecord.create(
      id: widget.existingRecord?.id,
      machineName: _machineNameController.text.trim(),
      machineNumber: _machineNumberController.text.trim(),
      operatorName: _operatorNameController.text.trim(),
      location: _locationController.text.trim(),
      billingMode: _billingMode,
      date: _billingMode == BillingMode.monthlyRent
          ? (_startDate ?? _selectedDate)
          : _selectedDate,
      startDate:
          _billingMode == BillingMode.monthlyRent ? _startDate : null,
      endDate: _billingMode == BillingMode.monthlyRent ? _endDate : null,
      monthlyRent: double.tryParse(_monthlyRentController.text) ?? 0,
      ratePerLoad: double.tryParse(_ratePerLoadController.text) ?? 0,
      totalLoads: int.tryParse(_totalLoadsController.text) ?? 0,
      diesel: _diesel,
      advance: _advance,
      remarks: _remarksController.text.trim(),
      createdBy: currentUser?.uid,
    );

    if (_isEditing) {
      context.read<MachineryBloc>().add(MachineryUpdateRecord(record));
    } else {
      context.read<MachineryBloc>().add(MachineryCreateRecord(record));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MachineryBloc, MachineryState>(
      listener: (context, state) {
        if (state is MachineryOperationSuccess) {
          context.pop();
        }
        if (state is MachineryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) => LoadingOverlay(
        isLoading: state is MachineryLoading,
        message: _isEditing ? 'Updating record...' : 'Saving record...',
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildToolbar(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailsSection(),
                        const SizedBox(height: 20),
                        _buildBillingSection(),
                        const SizedBox(height: 20),
                        _buildFinancialSection(),
                        const SizedBox(height: 20),
                        _buildRemarksSection(),
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
            _isEditing ? 'Edit Machinery Record' : 'New Machinery Record',
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

  Widget _buildDetailsSection() {
    return _MacSection(
      title: 'Machine Details',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _machineNameController,
                  label: 'Machine Name',
                  prefixIcon: Icons.construction_outlined,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Machine name is required'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _machineNumberController,
                  label: 'Machine Number',
                  prefixIcon: Icons.tag,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _operatorNameController,
                  label: 'Operator',
                  prefixIcon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _locationController,
                  label: 'Location',
                  prefixIcon: Icons.location_on_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingSection() {
    return _MacSection(
      title: 'Billing',
      child: Column(
        children: [
          BillingModeSelector(
            selectedMode: _billingMode,
            onChanged: (mode) => setState(() => _billingMode = mode),
          ),
          const SizedBox(height: 16),
          if (_billingMode == BillingMode.monthlyRent)
            _buildMonthlyRentFields()
          else
            _buildPerLoadFields(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: AppTextStyles.subtitle),
                Text(
                  '₹${_totalAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRentFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Start Date',
                readOnly: true,
                prefixIcon: Icons.calendar_today_outlined,
                controller: TextEditingController(
                  text: _startDate != null
                      ? DateFormatter.toDisplay(_startDate!)
                      : 'Select',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'End Date',
                readOnly: true,
                prefixIcon: Icons.calendar_today_outlined,
                controller: TextEditingController(
                  text: _endDate != null
                      ? DateFormatter.toDisplay(_endDate!)
                      : 'Select',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                    firstDate: _startDate ?? DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _monthlyRentController,
          label: 'Monthly Rent',
          prefixIcon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildPerLoadFields() {
    return Column(
      children: [
        AppTextField(
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _ratePerLoadController,
                label: 'Rate per Load',
                prefixIcon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: _totalLoadsController,
                label: 'Total Loads',
                prefixIcon: Icons.repeat,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
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
                _summaryRow(
                    'Total Amount', '₹${_totalAmount.toStringAsFixed(0)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 0.5),
                ),
                _summaryRow('Diesel', '₹${_diesel.toStringAsFixed(0)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 0.5),
                ),
                _summaryRow('Advance', '- ₹${_advance.toStringAsFixed(0)}'),
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

  Widget _buildRemarksSection() {
    return _MacSection(
      title: 'Remarks',
      child: AppTextField(
        controller: _remarksController,
        label: 'Notes (optional)',
        prefixIcon: Icons.notes_outlined,
        maxLines: 3,
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

class _MacSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _MacSection({required this.title, required this.child});

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
            child: Text(title, style: AppTextStyles.heading3),
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
