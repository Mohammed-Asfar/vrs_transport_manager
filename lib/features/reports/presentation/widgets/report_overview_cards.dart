import 'package:flutter/material.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_data.dart';

class ReportOverviewCards extends StatefulWidget {
  final ReportOverview overview;

  const ReportOverviewCards({super.key, required this.overview});

  @override
  State<ReportOverviewCards> createState() => _ReportOverviewCardsState();
}

class _ReportOverviewCardsState extends State<ReportOverviewCards> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void didUpdateWidget(ReportOverviewCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overview != widget.overview) {
      setState(() => _visible = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardData(
          'Records', '${widget.overview.totalRecords}', Icons.description_outlined, null),
      _CardData(
          'Transporters', '${widget.overview.uniqueTransporters}', Icons.person_outline_rounded, null),
      _CardData(
          'Vehicles', '${widget.overview.uniqueVehicles}', Icons.local_shipping_outlined, null),
      _CardData(
          'Total Loads', '${widget.overview.totalLoads}', Icons.inventory_2_outlined, null),
      _CardData('Total Amount',
          '₹${widget.overview.totalAmount.toStringAsFixed(0)}', Icons.payments_outlined, AppColors.accent),
      _CardData(
          'Balance',
          '₹${widget.overview.totalBalance.toStringAsFixed(0)}',
          Icons.account_balance_wallet_outlined,
          widget.overview.totalBalance >= 0
              ? AppColors.success
              : AppColors.error),
    ];

    return Row(
      children: cards.asMap().entries.map((entry) {
        final i = entry.key;
        final card = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < cards.length - 1 ? 10 : 0),
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 300 + i * 80),
              opacity: _visible ? 1.0 : 0.0,
              curve: Curves.easeOut,
              child: AnimatedSlide(
                duration: Duration(milliseconds: 300 + i * 80),
                offset: _visible ? Offset.zero : const Offset(0, 0.15),
                curve: Curves.easeOut,
                child: _StatCard(data: card),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CardData {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _CardData(this.label, this.value, this.icon, this.valueColor);
}

class _StatCard extends StatelessWidget {
  final _CardData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(data.label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: AppTextStyles.heading3.copyWith(
              color: data.valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
