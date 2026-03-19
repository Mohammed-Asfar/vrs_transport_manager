import 'package:flutter/material.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';

class TransporterFilter extends StatelessWidget {
  final String? selectedTransporter;
  final List<String> availableTransporters;
  final ValueChanged<String?> onChanged;

  const TransporterFilter({
    super.key,
    required this.selectedTransporter,
    required this.availableTransporters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transporter',
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedTransporter,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              icon: const Icon(Icons.expand_more_rounded,
                  size: 18, color: AppColors.textTertiary),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Transporters'),
                ),
                ...availableTransporters.map((name) =>
                    DropdownMenuItem<String?>(
                      value: name,
                      child: Text(name, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
