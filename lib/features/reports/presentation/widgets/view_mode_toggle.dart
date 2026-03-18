import 'package:flutter/material.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_config.dart';

class ViewModeToggle extends StatelessWidget {
  final ReportViewMode viewMode;
  final ValueChanged<ReportViewMode> onChanged;

  const ViewModeToggle({
    super.key,
    required this.viewMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Group By',
            style: AppTextStyles.label
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.separator, width: 0.5),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final halfWidth = constraints.maxWidth / 2;
              return Stack(
                children: [
                  // Sliding indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: viewMode == ReportViewMode.transporter
                        ? 2
                        : halfWidth,
                    top: 2,
                    bottom: 2,
                    width: halfWidth - 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  // Labels
                  Row(
                    children: [
                      _ToggleSegment(
                        icon: Icons.person_outline_rounded,
                        label: 'Transporter',
                        isSelected:
                            viewMode == ReportViewMode.transporter,
                        onTap: () =>
                            onChanged(ReportViewMode.transporter),
                      ),
                      _ToggleSegment(
                        icon: Icons.local_shipping_outlined,
                        label: 'Vehicle',
                        isSelected: viewMode == ReportViewMode.vehicle,
                        onTap: () => onChanged(ReportViewMode.vehicle),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleSegment({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textTertiary),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textTertiary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
