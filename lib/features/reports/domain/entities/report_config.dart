import 'package:equatable/equatable.dart';

enum ReportViewMode { transporter, vehicle }

enum DateRangePreset { thisWeek, lastWeek, thisMonth, custom }

class ReportConfig extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final ReportViewMode viewMode;
  final DateRangePreset preset;

  const ReportConfig({
    required this.startDate,
    required this.endDate,
    required this.viewMode,
    required this.preset,
  });

  ReportConfig copyWith({
    DateTime? startDate,
    DateTime? endDate,
    ReportViewMode? viewMode,
    DateRangePreset? preset,
  }) {
    return ReportConfig(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      viewMode: viewMode ?? this.viewMode,
      preset: preset ?? this.preset,
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
      viewMode: ReportViewMode.transporter,
      preset: DateRangePreset.thisWeek,
    );
  }

  /// Resolve dates for a given preset
  factory ReportConfig.fromPreset(
    DateRangePreset preset, {
    ReportViewMode viewMode = ReportViewMode.transporter,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (preset) {
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
      viewMode: viewMode,
      preset: preset,
    );
  }

  @override
  List<Object> get props => [startDate, endDate, viewMode, preset];
}
