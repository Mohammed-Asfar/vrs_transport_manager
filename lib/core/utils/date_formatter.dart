import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _fullFormat = DateFormat('dd MMM yyyy, hh:mm a');

  /// Format: 14.03.2026
  static String toDisplay(DateTime date) => _displayFormat.format(date);

  /// Format: 2026-03-14
  static String toApi(DateTime date) => _apiFormat.format(date);

  /// Format: 14 Mar 2026, 03:30 PM
  static String toFull(DateTime date) => _fullFormat.format(date);

  static final DateFormat _rangeFormat = DateFormat('dd MMM yyyy');

  /// Format: "01 Mar 2026 – 15 Mar 2026"
  static String toRange(DateTime start, DateTime end) =>
      '${_rangeFormat.format(start)} - ${_rangeFormat.format(end)}';

  /// Parse from display format: 14.03.2026
  static DateTime? fromDisplay(String dateStr) {
    try {
      return _displayFormat.parse(dateStr);
    } catch (_) {
      return null;
    }
  }
}
