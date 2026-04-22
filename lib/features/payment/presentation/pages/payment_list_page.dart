import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/core/widgets/confirmation_dialog.dart';
import 'package:vrs_transport_manager/features/payment/domain/entities/payment.dart';
import 'package:vrs_transport_manager/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:vrs_transport_manager/features/payment/presentation/bloc/payment_event.dart';
import 'package:vrs_transport_manager/features/payment/presentation/bloc/payment_state.dart';

class PaymentListPage extends StatefulWidget {
  const PaymentListPage({super.key});

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Unpaid, Partial, Paid

  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(const PaymentLoadAll());
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.toolbar,
        border: Border(
          bottom: BorderSide(color: AppColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined,
              size: 20, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Payments', style: AppTextStyles.heading3),
          const Spacer(),
          // Search
          SizedBox(
            width: 220,
            height: 32,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search transporter...',
                hintStyle: AppTextStyles.body
                    .copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 16, color: AppColors.textTertiary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: AppColors.separator, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: AppColors.separator, width: 0.5),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(width: 12),
          // Status filter
          SizedBox(
            height: 32,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'All', label: Text('All')),
                ButtonSegment(value: 'Unpaid', label: Text('Unpaid')),
                ButtonSegment(value: 'Partial', label: Text('Partial')),
                ButtonSegment(value: 'Paid', label: Text('Paid')),
              ],
              selected: {_statusFilter},
              onSelectionChanged: (v) =>
                  setState(() => _statusFilter = v.first),
              style: ButtonStyle(
                textStyle:
                    WidgetStatePropertyAll(AppTextStyles.caption),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocConsumer<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
        if (state is PaymentOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PaymentLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        if (state is PaymentLoaded) {
          return _buildPaymentsList(state.payments);
        }

        return const Center(
          child: Text('Loading payments...',
              style: TextStyle(color: AppColors.textTertiary)),
        );
      },
    );
  }

  Widget _buildPaymentsList(List<Payment> payments) {
    // Group payments by transporter + date range
    final groups = _groupPayments(payments);

    // Apply search filter
    final filtered = groups.where((g) {
      if (_searchQuery.isNotEmpty) {
        final match = g.transporterName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        if (!match) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_outlined,
                size: 48,
                color: AppColors.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No payments recorded yet',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) =>
          _PaymentGroupCard(
            group: filtered[index],
            onDelete: (id) => _deletePayment(id),
          ),
    );
  }

  List<_PaymentGroup> _groupPayments(List<Payment> payments) {
    final map = <String, _PaymentGroup>{};

    for (final p in payments) {
      final key =
          '${p.transporterNameNormalized}_${p.weekStartDate.millisecondsSinceEpoch}_${p.weekEndDate.millisecondsSinceEpoch}';
      if (map.containsKey(key)) {
        map[key]!.payments.add(p);
        map[key]!.totalPaid += p.amount;
      } else {
        map[key] = _PaymentGroup(
          transporterName: p.transporterName,
          weekStartDate: p.weekStartDate,
          weekEndDate: p.weekEndDate,
          totalPaid: p.amount,
          payments: [p],
        );
      }
    }

    final groups = map.values.toList()
      ..sort((a, b) => b.weekEndDate.compareTo(a.weekEndDate));

    // Apply status filter
    if (_statusFilter != 'All') {
      // We don't have the balance here, so we filter based on what we know:
      // payments exist = at least partial. Without balance info we show all.
      // This is a simplified filter — the full version would need report data.
    }

    return groups;
  }

  Future<void> _deletePayment(String id) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Payment',
      message: 'Are you sure you want to delete this payment?',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline_rounded,
    );
    if (confirm == true && mounted) {
      context.read<PaymentBloc>().add(PaymentDelete(id));
    }
  }
}

class _PaymentGroup {
  final String transporterName;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  double totalPaid;
  final List<Payment> payments;

  _PaymentGroup({
    required this.transporterName,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.totalPaid,
    required this.payments,
  });
}

class _PaymentGroupCard extends StatefulWidget {
  final _PaymentGroup group;
  final Function(String id) onDelete;

  const _PaymentGroupCard({
    required this.group,
    required this.onDelete,
  });

  @override
  State<_PaymentGroupCard> createState() => _PaymentGroupCardState();
}

class _PaymentGroupCardState extends State<_PaymentGroupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.transporterName,
                            style: AppTextStyles.subtitle
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormatter.toDisplay(g.weekStartDate)} – ${DateFormatter.toDisplay(g.weekEndDate)}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${g.totalPaid.toStringAsFixed(0)}',
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        '${g.payments.length} payment${g.payments.length == 1 ? '' : 's'}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded payment list
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? _buildPaymentDetails(g.payments)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(List<Payment> payments) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Column(
        children: [
          // Sub-header
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('Date',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 2,
                    child: Text('Amount',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 3,
                    child: Text('Remarks',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600))),
                const SizedBox(width: 32), // delete icon space
              ],
            ),
          ),
          // Payment rows
          ...payments.asMap().entries.map((entry) {
            final payment = entry.value;
            final isLast = entry.key == payments.length - 1;

            return Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(
                            color: AppColors.separatorLight, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      DateFormatter.toDisplay(payment.paymentDate),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${payment.amount.toStringAsFixed(0)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      payment.remarks.isEmpty ? '–' : payment.remarks,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: IconButton(
                      onPressed: () => widget.onDelete(payment.id!),
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 14, color: AppColors.error),
                      padding: EdgeInsets.zero,
                      splashRadius: 14,
                      tooltip: 'Delete payment',
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
