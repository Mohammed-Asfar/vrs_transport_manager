import 'package:flutter/material.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';

class ReportEmptyState extends StatelessWidget {
  final bool isNoResults;

  const ReportEmptyState({super.key, this.isNoResults = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNoResults
                ? Icons.calendar_month_outlined
                : Icons.summarize_outlined,
            size: 44,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            isNoResults
                ? 'No records found'
                : 'Generate a summary report',
            style: AppTextStyles.heading3
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            isNoResults
                ? 'No transport records found for this date range'
                : 'Select a date range and click "Generate Report"',
            style:
                AppTextStyles.body.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
