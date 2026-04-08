class NumberToWords {
  NumberToWords._();

  static const _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen',
  ];

  static const _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety',
  ];

  static String convert(num amount) {
    final whole = amount.toInt();
    final paise = ((amount - whole) * 100).round();

    if (whole == 0 && paise == 0) return 'Zero Only';

    final parts = <String>[];
    if (whole > 0) parts.add(_convertIndian(whole));
    if (paise > 0) parts.add('Paise ${_convertBelow100(paise)}');

    return '${parts.join(' & ')} Only';
  }

  static String _convertIndian(int number) {
    final majorParts = <String>[];

    // Crores (1,00,00,000+)
    if (number >= 10000000) {
      majorParts.add('${_convertBelow100(number ~/ 10000000)} Crore');
      number %= 10000000;
    }

    // Lakhs (1,00,000+)
    if (number >= 100000) {
      majorParts.add('${_convertBelow100(number ~/ 100000)} Lakh');
      number %= 100000;
    }

    // Thousands (1,000+)
    if (number >= 1000) {
      majorParts.add('${_convertBelow100(number ~/ 1000)} Thousand');
      number %= 1000;
    }

    // Remainder below 1000
    final minor = _convertBelow1000(number);

    if (majorParts.isEmpty) return minor;
    if (minor.isEmpty) return majorParts.join(' ');
    // Use '&' only before small remainders (below 100)
    final separator = number < 100 ? ' & ' : ' ';
    return '${majorParts.join(' ')}$separator$minor';
  }

  static String _convertBelow1000(int number) {
    if (number <= 0) return '';
    if (number < 100) return _convertBelow100(number);
    final hundreds = '${_ones[number ~/ 100]} Hundred';
    final remainder = number % 100;
    if (remainder == 0) return hundreds;
    return '$hundreds ${_convertBelow100(remainder)}';
  }

  static String _convertBelow100(int number) {
    if (number < 20) return _ones[number];
    final ten = _tens[number ~/ 10];
    final one = _ones[number % 10];
    return one.isEmpty ? ten : '$ten $one';
  }
}
