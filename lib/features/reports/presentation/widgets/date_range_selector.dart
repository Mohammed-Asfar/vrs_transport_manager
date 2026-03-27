import 'package:flutter/material.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_config.dart';

class DateRangeSelector extends StatefulWidget {
  final ReportConfig config;
  final ValueChanged<ReportConfig> onChanged;

  const DateRangeSelector({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  late DateTime _customStart;
  late DateTime _customEnd;

  @override
  void initState() {
    super.initState();
    _customStart = widget.config.startDate;
    _customEnd = widget.config.endDate;
  }

  void _selectPreset(DateRangePreset preset) {
    if (preset == DateRangePreset.custom) {
      widget.onChanged(widget.config.copyWith(
        preset: preset,
        startDate: _customStart,
        endDate: _customEnd,
      ));
    } else {
      widget.onChanged(ReportConfig.fromPreset(
        preset,
        selectedTransporter: widget.config.selectedTransporter,
      ));
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _customStart : _customEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _customStart = DateTime(picked.year, picked.month, picked.day);
        if (_customStart.isAfter(_customEnd)) {
          _customEnd =
              DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      } else {
        _customEnd =
            DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        if (_customEnd.isBefore(_customStart)) {
          _customStart = DateTime(picked.year, picked.month, picked.day);
        }
      }
    });

    widget.onChanged(widget.config.copyWith(
      preset: DateRangePreset.custom,
      startDate: _customStart,
      endDate: _customEnd,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date Range',
            style: AppTextStyles.label
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),

        // Preset pills - 2x2 grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DateRangePreset.values.map((preset) {
            final isSelected = widget.config.preset == preset;
            return _PresetPill(
              label: _presetLabel(preset),
              isSelected: isSelected,
              onTap: () => _selectPreset(preset),
            );
          }).toList(),
        ),

        // Custom date fields
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: widget.config.preset == DateRangePreset.custom
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'From',
                          date: _customStart,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DateField(
                          label: 'To',
                          date: _customEnd,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 10),

        // Resolved range display
        Text(
          DateFormatter.toRange(
              widget.config.startDate, widget.config.endDate),
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  String _presetLabel(DateRangePreset preset) {
    return switch (preset) {
      DateRangePreset.today => 'Today',
      DateRangePreset.thisWeek => 'This Week',
      DateRangePreset.lastWeek => 'Last Week',
      DateRangePreset.thisMonth => 'This Month',
      DateRangePreset.custom => 'Custom',
    };
  }
}

class _PresetPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PresetPill> createState() => _PresetPillState();
}

class _PresetPillState extends State<_PresetPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accent
                : _hovered
                    ? AppColors.surfaceSecondary
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.accent
                  : AppColors.separator,
              width: 0.5,
            ),
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.caption.copyWith(
              color: widget.isSelected
                  ? Colors.white
                  : AppColors.textSecondary,
              fontWeight:
                  widget.isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatefulWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered ? AppColors.accent : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textTertiary, fontSize: 10)),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    DateFormatter.toDisplay(widget.date),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
