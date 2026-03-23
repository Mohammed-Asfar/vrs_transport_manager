import 'package:flutter/material.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/billing_mode.dart';

class BillingModeSelector extends StatelessWidget {
  final BillingMode selectedMode;
  final ValueChanged<BillingMode> onChanged;

  const BillingModeSelector({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildOption(
            label: 'Monthly Rent',
            icon: Icons.calendar_month_outlined,
            mode: BillingMode.monthlyRent,
          ),
          const SizedBox(width: 4),
          _buildOption(
            label: 'Per Load',
            icon: Icons.local_shipping_outlined,
            mode: BillingMode.perLoad,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required IconData icon,
    required BillingMode mode,
  }) {
    final isSelected = selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
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
