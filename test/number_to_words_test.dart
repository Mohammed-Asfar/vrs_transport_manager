import 'package:flutter_test/flutter_test.dart';
import 'package:vrs_transport_manager/core/utils/number_to_words.dart';

void main() {
  group('NumberToWords', () {
    test('converts single-digit numbers', () {
      expect(NumberToWords.convert(5), 'Five Only');
    });

    test('converts two-digit numbers', () {
      expect(NumberToWords.convert(42), 'Forty Two Only');
    });

    test('converts hundreds', () {
      expect(NumberToWords.convert(300), 'Three Hundred Only');
    });

    test('converts thousands', () {
      expect(NumberToWords.convert(7500), 'Seven Thousand Five Hundred Only');
    });

    test('converts lakhs', () {
      expect(NumberToWords.convert(150000), 'One Lakh Fifty Thousand Only');
      expect(NumberToWords.convert(2035063),
          'Twenty Lakh Thirty Five Thousand & Sixty Three Only');
    });

    test('converts crores', () {
      expect(NumberToWords.convert(10000000), 'One Crore Only');
      expect(NumberToWords.convert(52300000),
          'Five Crore Twenty Three Lakh Only');
    });

    test('converts zero', () {
      expect(NumberToWords.convert(0), 'Zero Only');
    });

    test('converts decimals with paise', () {
      expect(NumberToWords.convert(1500.50),
          'One Thousand Five Hundred & Paise Fifty Only');
    });

    test('ignores negligible paise (< 1 paisa)', () {
      expect(NumberToWords.convert(1500.004),
          'One Thousand Five Hundred Only');
    });

    test('converts real invoice amount from paper invoice', () {
      expect(NumberToWords.convert(2035063),
          'Twenty Lakh Thirty Five Thousand & Sixty Three Only');
    });
  });
}
