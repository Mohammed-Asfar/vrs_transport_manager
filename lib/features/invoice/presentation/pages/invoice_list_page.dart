import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/widgets/confirmation_dialog.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/bloc/invoice_event.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/bloc/invoice_state.dart';

final _currencyFormat = NumberFormat('#,##,###', 'en_IN');

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(const InvoiceLoadRecords());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.toolbar,
        border: Border(
          bottom: BorderSide(color: AppColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 20, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Invoices', style: AppTextStyles.heading3),
          const Spacer(),
          SizedBox(
            width: 280,
            height: 36,
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search invoices...',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 8, right: 4),
                  child: Icon(Icons.search,
                      size: 16, color: AppColors.textTertiary),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 32, minHeight: 36),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          context
                              .read<InvoiceBloc>()
                              .add(const InvoiceClearSearch());
                          setState(() {});
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.close,
                              size: 14, color: AppColors.textTertiary),
                        ),
                      )
                    : null,
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 24, minHeight: 24),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.trim().isEmpty) {
                  context
                      .read<InvoiceBloc>()
                      .add(const InvoiceClearSearch());
                } else {
                  context
                      .read<InvoiceBloc>()
                      .add(InvoiceSearchRecords(value));
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/invoices/create'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Invoice'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocConsumer<InvoiceBloc, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error),
          );
        }
        if (state is InvoiceOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success),
          );
          context.read<InvoiceBloc>().add(const InvoiceLoadRecords());
        }
      },
      builder: (context, state) {
        if (state is InvoiceLoading) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.accent),
            ),
          );
        }

        if (state is InvoiceLoaded) {
          if (state.records.isEmpty) {
            return _buildEmptyState(state.isSearchResult);
          }
          return _buildList(
              state.records, state.isSearchResult, state.searchQuery);
        }

        if (state is InvoiceError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 36, color: AppColors.error.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(state.message,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 28,
                  child: OutlinedButton(
                    onPressed: () => context
                        .read<InvoiceBloc>()
                        .add(const InvoiceLoadRecords()),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState(bool isSearch) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearch ? Icons.search_off_rounded : Icons.receipt_long_outlined,
            size: 44,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            isSearch ? 'No invoices found' : 'No invoices yet',
            style:
                AppTextStyles.heading3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? 'Try a different search term'
                : 'Click "+ New Invoice" to create your first invoice',
            style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      List<InvoiceRecord> records, bool isSearch, String query) {
    return Column(
      children: [
        // Column header
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: AppColors.surfaceSecondary,
            border: Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                  width: 140,
                  child:
                      Text('Invoice No', style: AppTextStyles.tableHeader)),
              SizedBox(
                  width: 80,
                  child: Text('Date', style: AppTextStyles.tableHeader)),
              const SizedBox(width: 16),
              Expanded(
                  child: Text('Client', style: AppTextStyles.tableHeader)),
              SizedBox(
                width: 120,
                child: Text('Amount',
                    style: AppTextStyles.tableHeader,
                    textAlign: TextAlign.right),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),

        // Status bar
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: AppColors.toolbar,
            border: Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Text(
                isSearch ? 'Search Results' : 'All Invoices',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${records.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Rows
        Expanded(
          child: Container(
            color: AppColors.surface,
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return _InvoiceRow(
                  record: record,
                  isLast: index == records.length - 1,
                  onTap: () => context.push('/invoices/detail/${record.id}'),
                  onEdit: () => context.push('/invoices/edit/${record.id}'),
                  onDelete: () => _deleteInvoice(record),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteInvoice(InvoiceRecord record) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Invoice',
      message: 'Delete invoice ${record.invoiceNumber}?',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline_rounded,
    );
    if (confirm == true && mounted) {
      context.read<InvoiceBloc>().add(InvoiceDeleteRecord(record.id!));
    }
  }
}

class _InvoiceRow extends StatefulWidget {
  final InvoiceRecord record;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InvoiceRow({
    required this.record,
    required this.isLast,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_InvoiceRow> createState() => _InvoiceRowState();
}

class _InvoiceRowState extends State<_InvoiceRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final date = widget.record.invoiceDate;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)}';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.accentLight : AppColors.surface,
            border: widget.isLast
                ? null
                : const Border(
                    bottom: BorderSide(
                        color: AppColors.separatorLight, width: 0.5),
                  ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  widget.record.invoiceNumber,
                  style: AppTextStyles.subtitle
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(dateStr, style: AppTextStyles.subtitle),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.record.client.companyName,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  '₹${_currencyFormat.format(widget.record.totalInvoiceValue.round())}',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                height: 36,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  icon: Icon(
                    Icons.more_horiz,
                    color: _hovered
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                    size: 20,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        widget.onTap();
                      case 'edit':
                        widget.onEdit();
                      case 'delete':
                        widget.onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    _menuItem('view', Icons.visibility_outlined, 'View'),
                    _menuItem('edit', Icons.edit_outlined, 'Edit'),
                    _menuItem('delete', Icons.delete_outline, 'Delete',
                        color: AppColors.error),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label,
      {Color? color}) {
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: AppTextStyles.body
                  .copyWith(color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }
}
