import 'package:equatable/equatable.dart';

enum DateRangePreset { today, thisWeek, lastWeek, thisMonth, custom }

enum ExportTarget { company, transporter }

class ReportConfig extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final DateRangePreset preset;
  final String? selectedTransporter;

  const ReportConfig({
    required this.startDate,
    required this.endDate,
    required this.preset,
    this.selectedTransporter,
  });

  ReportConfig copyWith({
    DateTime? startDate,
    DateTime? endDate,
    DateRangePreset? preset,
    String? selectedTransporter,
    bool clearSelectedTransporter = false,
  }) {
    return ReportConfig(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      preset: preset ?? this.preset,
      selectedTransporter: clearSelectedTransporter
          ? null
          : (selectedTransporter ?? this.selectedTransporter),
    );
  }

  /// Create a default config for "This Week"
  factory ReportConfig.thisWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return ReportConfig(
      startDate: DateTime(monday.year, monday.month, monday.day),
      endDate: DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
      preset: DateRangePreset.thisWeek,
    );
  }

  /// Resolve dates for a given preset
  factory ReportConfig.fromPreset(
    DateRangePreset preset, {
    DateTime? customStart,
    DateTime? customEnd,
    String? selectedTransporter,
  }) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (preset) {
      case DateRangePreset.today:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      case DateRangePreset.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      case DateRangePreset.lastWeek:
        final lastMonday =
            now.subtract(Duration(days: now.weekday - 1 + 7));
        final lastSunday = lastMonday.add(const Duration(days: 6));
        start = DateTime(lastMonday.year, lastMonday.month, lastMonday.day);
        end = DateTime(
            lastSunday.year, lastSunday.month, lastSunday.day, 23, 59, 59);
      case DateRangePreset.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      case DateRangePreset.custom:
        start = customStart ?? DateTime(now.year, now.month, 1);
        end = customEnd ??
            DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    return ReportConfig(
      startDate: start,
      endDate: end,
      preset: preset,
      selectedTransporter: selectedTransporter,
    );
  }

  @override
  List<Object?> get props => [startDate, endDate, preset, selectedTransporter];
}
