import 'package:flutter_test/flutter_test.dart';
import 'package:vrs_transport_manager/core/utils/invoice_number_formatter.dart';

void main() {
  group('InvoiceNumberFormatter', () {
    test('formats with month abbreviation, year, and zero-padded serial', () {
      expect(
        InvoiceNumberFormatter.format(
          date: DateTime(2026, 3, 31),
          serial: 41,
        ),
        'VRS-MAR-2026-041',
      );
    });

    test('formats single-digit serial with zero padding', () {
      expect(
        InvoiceNumberFormatter.format(
          date: DateTime(2026, 4, 8),
          serial: 1,
        ),
        'VRS-APR-2026-001',
      );
    });

    test('handles large serial numbers beyond 3 digits', () {
      expect(
        InvoiceNumberFormatter.format(
          date: DateTime(2026, 12, 1),
          serial: 1234,
        ),
        'VRS-DEC-2026-1234',
      );
    });

    test('generates counter key from date', () {
      expect(
        InvoiceNumberFormatter.counterKey(DateTime(2026, 3, 15)),
        '2026-03',
      );
      expect(
        InvoiceNumberFormatter.counterKey(DateTime(2026, 11, 1)),
        '2026-11',
      );
    });
  });
}
