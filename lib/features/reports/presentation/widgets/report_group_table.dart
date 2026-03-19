import 'package:flutter/material.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_data.dart';

class ReportGroupTable extends StatelessWidget {
  final ReportData data;

  const ReportGroupTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Column header
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: AppColors.surfaceSecondary,
            border: Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 28), // expand icon space
              Expanded(
                  flex: 3,
                  child:
                      Text('Transporter', style: AppTextStyles.tableHeader)),
              Expanded(
                  child:
                      Text('Trips', style: AppTextStyles.tableHeader)),
              Expanded(
                  child:
                      Text('Loads', style: AppTextStyles.tableHeader)),
              Expanded(
                  flex: 2,
                  child: Text('Amount',
                      style: AppTextStyles.tableHeader,
                      textAlign: TextAlign.right)),
              Expanded(
                  flex: 2,
                  child: Text('Balance',
                      style: AppTextStyles.tableHeader,
                      textAlign: TextAlign.right)),
              const SizedBox(width: 8),
            ],
          ),
        ),

        // Group rows
        Expanded(
          child: ListView.builder(
            itemCount: data.groups.length,
            itemBuilder: (context, index) {
              return _GroupRow(
                group: data.groups[index],
                isLast: index == data.groups.length - 1,
              );
            },
          ),
        ),

        // Totals row (fixed at bottom)
        _TotalsRow(overview: data.overview),
      ],
    );
  }
}

class _GroupRow extends StatefulWidget {
  final ReportGroup group;
  final bool isLast;

  const _GroupRow({
    required this.group,
    required this.isLast,
  });

  @override
  State<_GroupRow> createState() => _GroupRowState();
}

class _GroupRowState extends State<_GroupRow>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main row
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _hovered ? AppColors.accentLight : AppColors.surface,
                border: !_expanded && !widget.isLast
                    ? const Border(
                        bottom: BorderSide(
                            color: AppColors.separatorLight, width: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.chevron_right_rounded,
                          size: 16, color: AppColors.textTertiary),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      widget.group.groupKey,
                      style: AppTextStyles.subtitle
                          .copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text('${widget.group.trips.length}',
                        style: AppTextStyles.tableCell
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: Text('${widget.group.totalLoads}',
                        style: AppTextStyles.tableCell
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${widget.group.totalAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.subtitle
                          .copyWith(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${widget.group.balance.toStringAsFixed(0)}',
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.group.balance >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),

        // Expanded trip details
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _expanded
              ? _ExpandedTrips(group: widget.group)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ExpandedTrips extends StatelessWidget {
  final ReportGroup group;

  const _ExpandedTrips({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 28, right: 8, bottom: 4),
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
                _subHeader('Date', flex: 2),
                _subHeader('Location', flex: 2),
                _subHeader('Vehicle', flex: 2),
                _subHeader('KM'),
                _subHeader('Rate'),
                _subHeader('Amount'),
                _subHeader('Loads'),
              ],
            ),
          ),
          // Trip rows
          ...group.trips.asMap().entries.map((entry) {
            final trip = entry.value;
            final isLast = entry.key == group.trips.length - 1;

            return Container(
              height: 32,
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
                  _subCell(DateFormatter.toDisplay(trip.date), flex: 2),
                  _subCell(trip.location, flex: 2),
                  _subCell(trip.vehicleNo, flex: 2),
                  _subCell(trip.km.toStringAsFixed(0)),
                  _subCell(trip.ratePerKm.toStringAsFixed(0)),
                  _subCell('₹${trip.amountPerTrip.toStringAsFixed(0)}'),
                  _subCell('${trip.noOfLoads}'),
                ],
              ),
            );
          }),
          // Financial footer
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(5)),
            ),
            child: Row(
              children: [
                Text('Diesel: ₹${group.dieselShare.toStringAsFixed(0)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary)),
                const SizedBox(width: 16),
                Text(
                    'Advance: ₹${group.advanceShare.toStringAsFixed(0)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary)),
                const Spacer(),
                Text(
                  'Balance: ₹${group.balance.toStringAsFixed(0)}',
                  style: AppTextStyles.caption.copyWith(
                    color: group.balance >= 0
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _subHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
    );
  }

  Widget _subCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textSecondary),
          overflow: TextOverflow.ellipsis),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final ReportOverview overview;

  const _TotalsRow({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSecondary,
        border: Border(
          top: BorderSide(color: AppColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28),
          Expanded(
            flex: 3,
            child: Text('Total',
                style: AppTextStyles.subtitle
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text('${overview.totalTrips}',
                style: AppTextStyles.tableCell
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text('${overview.totalLoads}',
                style: AppTextStyles.tableCell
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${overview.totalAmount.toStringAsFixed(0)}',
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${overview.totalBalance.toStringAsFixed(0)}',
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w700,
                color: overview.totalBalance >= 0
                    ? AppColors.success
                    : AppColors.error,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
