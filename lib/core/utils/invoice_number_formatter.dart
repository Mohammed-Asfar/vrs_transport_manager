class InvoiceNumberFormatter {
  InvoiceNumberFormatter._();

  static const _months = [
    '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  /// Formats an invoice number as VRS-{MMM}-{YYYY}-{NNN}
  static String format({required DateTime date, required int serial}) {
    final month = _months[date.month];
    final year = date.year;
    final serialStr = serial.toString().padLeft(3, '0');
    return 'VRS-$month-$year-$serialStr';
  }

  /// Returns the counter key for a given date (YYYY-MM)
  static String counterKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }
}
