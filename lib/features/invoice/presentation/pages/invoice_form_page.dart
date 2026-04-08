import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/core/widgets/app_text_field.dart';
import 'package:vrs_transport_manager/core/widgets/loading_overlay.dart';
import 'package:vrs_transport_manager/di/injection_container.dart';
import 'package:vrs_transport_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:vrs_transport_manager/features/client/domain/entities/client.dart';
import 'package:vrs_transport_manager/features/client/presentation/bloc/client_bloc.dart';
import 'package:vrs_transport_manager/features/client/presentation/bloc/client_event.dart';
import 'package:vrs_transport_manager/features/client/presentation/bloc/client_state.dart';
import 'package:vrs_transport_manager/core/utils/number_to_words.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_line_item.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_section.dart';
import 'package:vrs_transport_manager/features/invoice/domain/usecases/invoice_usecases.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/bloc/invoice_event.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/bloc/invoice_state.dart';

final _currencyFormat = NumberFormat('#,##,###.##', 'en_IN');

const _defaultUnits = ['Cum', 'Cum-Km', 'Sqm', 'Rmt', 'Nos', 'Hrs'];

class InvoiceFormPage extends StatefulWidget {
  final InvoiceRecord? existingRecord;

  const InvoiceFormPage({super.key, this.existingRecord});

  @override
  State<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends State<InvoiceFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _invoiceNumberController;
  late DateTime _invoiceDate;
  Client? _selectedClient;
  late List<_SectionFormData> _sections;

  // Tax
  bool _isInterState = false;
  late TextEditingController _cgstController;
  late TextEditingController _sgstController;
  late TextEditingController _igstController;

  // Recoveries
  late TextEditingController _tdsController;
  late TextEditingController _retentionController;

  bool get _isEditing => widget.existingRecord != null;
  bool _numberGenerated = false;

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;

    _invoiceNumberController =
        TextEditingController(text: record?.invoiceNumber ?? '');
    _invoiceDate = record?.invoiceDate ?? DateTime.now();
    _selectedClient = record?.client;

    // Tax
    _isInterState = record != null && record.igstPercent > 0;
    _cgstController = TextEditingController(
        text: record?.cgstPercent.toString() ?? '9');
    _sgstController = TextEditingController(
        text: record?.sgstPercent.toString() ?? '9');
    _igstController = TextEditingController(
        text: record?.igstPercent.toString() ?? '18');

    // Recoveries
    _tdsController = TextEditingController(
        text: record?.tdsPercent.toString() ?? '1');
    _retentionController = TextEditingController(
        text: record?.retentionPercent.toString() ?? '5');

    if (record != null) {
      _sections = record.sections
          .map((s) => _SectionFormData.fromSection(s))
          .toList();
    } else {
      _sections = [
        _SectionFormData(header: 'Construction of Earth Works'),
      ];
    }

    // Generate invoice number for new invoices
    if (!_isEditing) {
      _generateInvoiceNumber();
    }
  }

  Future<void> _generateInvoiceNumber() async {
    final result =
        await sl<PreviewInvoiceNumberUseCase>()(_invoiceDate);
    result.fold(
      (_) {},
      (number) {
        if (mounted && !_numberGenerated) {
          _numberGenerated = true;
          _invoiceNumberController.text = number;
        }
      },
    );
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _cgstController.dispose();
    _sgstController.dispose();
    _igstController.dispose();
    _tdsController.dispose();
    _retentionController.dispose();
    for (final section in _sections) {
      section.dispose();
    }
    super.dispose();
  }

  double get _totalValue {
    double total = 0;
    for (final section in _sections) {
      for (final item in section.items) {
        total += item.totalAmount;
      }
    }
    return total;
  }

  double get _cgstPercent =>
      _isInterState ? 0 : (double.tryParse(_cgstController.text) ?? 0);
  double get _sgstPercent =>
      _isInterState ? 0 : (double.tryParse(_sgstController.text) ?? 0);
  double get _igstPercent =>
      !_isInterState ? 0 : (double.tryParse(_igstController.text) ?? 0);
  double get _cgstAmount => _totalValue * _cgstPercent / 100;
  double get _sgstAmount => _totalValue * _sgstPercent / 100;
  double get _igstAmount => _totalValue * _igstPercent / 100;
  double get _subTotal => _totalValue + _cgstAmount + _sgstAmount + _igstAmount;
  double get _tdsPercent => double.tryParse(_tdsController.text) ?? 0;
  double get _retentionPercent =>
      double.tryParse(_retentionController.text) ?? 0;
  double get _tdsAmount => _subTotal * _tdsPercent / 100;
  double get _retentionAmount => _subTotal * _retentionPercent / 100;
  double get _totalInvoiceValue =>
      _subTotal - _tdsAmount - _retentionAmount;

  void _addSection() {
    setState(() {
      _sections.add(_SectionFormData(header: ''));
    });
  }

  void _removeSection(int index) {
    if (_sections.length <= 1) return;
    setState(() {
      _sections[index].dispose();
      _sections.removeAt(index);
    });
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final currentUser = sl<AuthRepository>().currentUser;

    final sections = _sections.map((s) {
      final items = s.items.map((item) {
        return InvoiceLineItem.create(
          sacCode: item.sacCodeController.text.trim(),
          description: item.descriptionController.text.trim(),
          unit: item.selectedUnit,
          qty: double.tryParse(item.qtyController.text) ?? 0,
          rate: double.tryParse(item.rateController.text) ?? 0,
        );
      }).toList();
      return InvoiceSection(
        header: s.headerController.text.trim(),
        lineItems: items,
      );
    }).toList();

    final record = InvoiceRecord.create(
      id: widget.existingRecord?.id,
      invoiceNumber: _invoiceNumberController.text.trim(),
      invoiceDate: _invoiceDate,
      client: _selectedClient!,
      sections: sections,
      cgstPercent: _cgstPercent,
      sgstPercent: _sgstPercent,
      igstPercent: _igstPercent,
      tdsPercent: _tdsPercent,
      retentionPercent: _retentionPercent,
      createdBy: currentUser?.uid,
    );

    if (_isEditing) {
      context.read<InvoiceBloc>().add(InvoiceUpdateRecord(record));
    } else {
      context.read<InvoiceBloc>().add(InvoiceCreateRecord(record));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvoiceBloc, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceOperationSuccess) {
          context.pop();
        }
        if (state is InvoiceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) => LoadingOverlay(
        isLoading: state is InvoiceLoading,
        message: _isEditing ? 'Updating invoice...' : 'Saving invoice...',
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
                        _buildHeaderSection(),
                        const SizedBox(height: 20),
                        _buildClientSection(),
                        const SizedBox(height: 20),
                        ..._buildSectionsList(),
                        const SizedBox(height: 12),
                        _buildAddSectionButton(),
                        const SizedBox(height: 20),
                        _buildTaxSection(),
                        const SizedBox(height: 20),
                        _buildRecoveriesSection(),
                        const SizedBox(height: 20),
                        _buildFinancialSummary(),
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
            _isEditing ? 'Edit Invoice' : 'New Invoice',
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
    return _FormSection(
      title: 'Invoice Details',
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _invoiceNumberController,
              label: 'Invoice Number',
              prefixIcon: Icons.tag,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Invoice number is required'
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextField(
              label: 'Invoice Date',
              readOnly: true,
              prefixIcon: Icons.calendar_today_outlined,
              controller: TextEditingController(
                text: DateFormatter.toDisplay(_invoiceDate),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _invoiceDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _invoiceDate = date);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection() {
    return _FormSection(
      title: 'Billed To',
      child: BlocProvider(
        create: (_) => sl<ClientBloc>()..add(const ClientLoadAll()),
        child: BlocConsumer<ClientBloc, ClientState>(
          listener: (context, state) {
            if (state is ClientCreated) {
              setState(() => _selectedClient = state.client);
              // Reload client list
              context.read<ClientBloc>().add(const ClientLoadAll());
            }
          },
          builder: (context, state) {
            final clients =
                state is ClientLoaded ? state.clients : <Client>[];

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Client>(
                        initialValue: _selectedClient != null
                            ? clients.cast<Client?>().firstWhere(
                                (c) => c?.id == _selectedClient?.id,
                                orElse: () => null,
                              )
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Select Client',
                          prefixIcon: const Icon(Icons.business_outlined,
                              size: 16, color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.surfaceSecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                                color: AppColors.border, width: 0.5),
                          ),
                        ),
                        items: clients
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.companyName,
                                      style: AppTextStyles.body),
                                ))
                            .toList(),
                        onChanged: (client) {
                          setState(() => _selectedClient = client);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddClientDialog(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Client'),
                      ),
                    ),
                  ],
                ),
                if (_selectedClient != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedClient!.companyName,
                            style: AppTextStyles.subtitle
                                .copyWith(fontWeight: FontWeight.w600)),
                        if (_selectedClient!.gstin.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('GSTIN: ${_selectedClient!.gstin}',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                        if (_selectedClient!.address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(_selectedClient!.address,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAddClientDialog(BuildContext parentContext) async {
    final nameController = TextEditingController();
    final gstinController = TextEditingController();
    final addressController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    final result = await showDialog<Client>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('New Client', style: AppTextStyles.heading3),
        content: Form(
          key: dialogFormKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: nameController,
                  label: 'Company Name',
                  prefixIcon: Icons.business_outlined,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: gstinController,
                  label: 'GSTIN',
                  prefixIcon: Icons.receipt_long_outlined,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: addressController,
                  label: 'Address',
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (dialogFormKey.currentState?.validate() ?? false) {
                final client = Client(
                  companyName: nameController.text.trim(),
                  gstin: gstinController.text.trim(),
                  address: addressController.text.trim(),
                );
                Navigator.pop(ctx, client);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    nameController.dispose();
    gstinController.dispose();
    addressController.dispose();

    if (result != null && parentContext.mounted) {
      parentContext.read<ClientBloc>().add(ClientCreate(result));
    }
  }

  List<Widget> _buildSectionsList() {
    int globalLineNumber = 0;
    return _sections.asMap().entries.map((entry) {
      final sectionIndex = entry.key;
      final section = entry.value;
      final startNumber = globalLineNumber + 1;
      globalLineNumber += section.items.length;

      return Padding(
        padding: EdgeInsets.only(
            bottom: sectionIndex < _sections.length - 1 ? 20 : 0),
        child: _buildSectionCard(section, sectionIndex, startNumber),
      );
    }).toList();
  }

  Widget _buildSectionCard(
      _SectionFormData section, int sectionIndex, int startNumber) {
    return _FormSection(
      title: 'Section ${sectionIndex + 1}',
      trailing: _sections.length > 1
          ? SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: const Icon(Icons.close, color: AppColors.error),
                onPressed: () => _removeSection(sectionIndex),
              ),
            )
          : null,
      child: Column(
        children: [
          AppTextField(
            controller: section.headerController,
            label: 'Section Header',
            prefixIcon: Icons.title,
            hint: 'e.g. Construction of Earth Works',
          ),
          const SizedBox(height: 16),

          // Line items
          ...section.items.asMap().entries.map((entry) {
            final itemIndex = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildLineItemRow(
                item,
                startNumber + itemIndex,
                () {
                  if (section.items.length > 1) {
                    setState(() {
                      section.items[itemIndex].dispose();
                      section.items.removeAt(itemIndex);
                    });
                  }
                },
              ),
            );
          }),

          // Add line item button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  section.items.add(_LineItemFormData());
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Line Item'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemRow(
      _LineItemFormData item, int serialNo, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Serial number
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('$serialNo',
                    style: AppTextStyles.caption
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: AppTextField(
                  controller: item.sacCodeController,
                  label: 'SAC Code',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: item.descriptionController,
                  label: 'Description',
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: const Icon(Icons.close, color: AppColors.textTertiary),
                  onPressed: onRemove,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 40),
              // Unit dropdown
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<String>(
                  initialValue: _defaultUnits.contains(item.selectedUnit)
                      ? item.selectedUnit
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: [
                    ..._defaultUnits.map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(u, style: AppTextStyles.body),
                        )),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => item.selectedUnit = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  controller: item.qtyController,
                  label: 'QTY',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  controller: item.rateController,
                  label: 'Rate',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 130,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '₹${_currencyFormat.format(item.totalAmount)}',
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddSectionButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _addSection,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add Section'),
      ),
    );
  }

  Widget _buildTaxSection() {
    return _FormSection(
      title: 'Tax',
      child: Column(
        children: [
          // Tax mode toggle
          Row(
            children: [
              Expanded(
                child: _TaxModeOption(
                  label: 'Intra-state (CGST + SGST)',
                  isSelected: !_isInterState,
                  onTap: () => setState(() => _isInterState = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TaxModeOption(
                  label: 'Inter-state (IGST)',
                  isSelected: _isInterState,
                  onTap: () => setState(() => _isInterState = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!_isInterState)
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _cgstController,
                    label: 'CGST %',
                    prefixIcon: Icons.percent,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '₹${_currencyFormat.format(_cgstAmount)}',
                      style: AppTextStyles.subtitle
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _sgstController,
                    label: 'SGST %',
                    prefixIcon: Icons.percent,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '₹${_currencyFormat.format(_sgstAmount)}',
                      style: AppTextStyles.subtitle
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _igstController,
                    label: 'IGST %',
                    prefixIcon: Icons.percent,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '₹${_currencyFormat.format(_igstAmount)}',
                      style: AppTextStyles.subtitle
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecoveriesSection() {
    return _FormSection(
      title: 'Recoveries',
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _tdsController,
              label: 'TDS %',
              prefixIcon: Icons.percent,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '- ₹${_currencyFormat.format(_tdsAmount)}',
                style: AppTextStyles.subtitle
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppTextField(
              controller: _retentionController,
              label: 'Retention Money %',
              prefixIcon: Icons.percent,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '- ₹${_currencyFormat.format(_retentionAmount)}',
                style: AppTextStyles.subtitle
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Column(
        children: [
          _summaryRow('Total Value', '₹${_currencyFormat.format(_totalValue)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 0.5),
          ),
          if (!_isInterState) ...[
            _summaryRow('CGST @ ${_cgstPercent.toStringAsFixed(0)}%',
                '₹${_currencyFormat.format(_cgstAmount)}'),
            const SizedBox(height: 4),
            _summaryRow('SGST @ ${_sgstPercent.toStringAsFixed(0)}%',
                '₹${_currencyFormat.format(_sgstAmount)}'),
          ] else
            _summaryRow('IGST @ ${_igstPercent.toStringAsFixed(0)}%',
                '₹${_currencyFormat.format(_igstAmount)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 0.5),
          ),
          _summaryRow('Sub Total', '₹${_currencyFormat.format(_subTotal)}',
              isBold: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 0.5),
          ),
          _summaryRow('TDS @ ${_tdsPercent.toStringAsFixed(0)}%',
              '- ₹${_currencyFormat.format(_tdsAmount)}'),
          const SizedBox(height: 4),
          _summaryRow(
              'Retention @ ${_retentionPercent.toStringAsFixed(0)}%',
              '- ₹${_currencyFormat.format(_retentionAmount)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 0.5),
          ),
          _summaryRow(
            'Total Invoice Value',
            '₹${_currencyFormat.format(_totalInvoiceValue)}',
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
              NumberToWords.convert(_totalInvoiceValue),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
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

// ── Form data classes ──

class _SectionFormData {
  final TextEditingController headerController;
  final List<_LineItemFormData> items;

  _SectionFormData({String header = ''})
      : headerController = TextEditingController(text: header),
        items = [_LineItemFormData()];

  factory _SectionFormData.fromSection(InvoiceSection section) {
    final data = _SectionFormData(header: section.header);
    data.items.clear();
    for (final item in section.lineItems) {
      data.items.add(_LineItemFormData.fromItem(item));
    }
    if (data.items.isEmpty) data.items.add(_LineItemFormData());
    return data;
  }

  void dispose() {
    headerController.dispose();
    for (final item in items) {
      item.dispose();
    }
  }
}

class _LineItemFormData {
  final TextEditingController sacCodeController;
  final TextEditingController descriptionController;
  String selectedUnit;
  final TextEditingController qtyController;
  final TextEditingController rateController;

  _LineItemFormData()
      : sacCodeController = TextEditingController(),
        descriptionController = TextEditingController(),
        selectedUnit = 'Cum',
        qtyController = TextEditingController(),
        rateController = TextEditingController();

  factory _LineItemFormData.fromItem(InvoiceLineItem item) {
    return _LineItemFormData()
      ..sacCodeController.text = item.sacCode
      ..descriptionController.text = item.description
      ..selectedUnit = item.unit
      ..qtyController.text = item.qty.toString()
      ..rateController.text = item.rate.toString();
  }

  double get totalAmount {
    final qty = double.tryParse(qtyController.text) ?? 0;
    final rate = double.tryParse(rateController.text) ?? 0;
    return qty * rate;
  }

  void dispose() {
    sacCodeController.dispose();
    descriptionController.dispose();
    qtyController.dispose();
    rateController.dispose();
  }
}

// ── Tax mode toggle ──

class _TaxModeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaxModeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.separator,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? AppColors.accent : AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable section widget ──

class _FormSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _FormSection({required this.title, required this.child, this.trailing});

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
                const Spacer(),
                ?trailing,
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
