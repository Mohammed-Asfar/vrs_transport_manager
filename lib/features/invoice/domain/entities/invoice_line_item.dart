import 'package:equatable/equatable.dart';

class InvoiceLineItem extends Equatable {
  final String sacCode;
  final String description;
  final String unit;
  final double qty;
  final double rate;
  final double totalAmount;

  const InvoiceLineItem({
    required this.sacCode,
    required this.description,
    required this.unit,
    required this.qty,
    required this.rate,
    required this.totalAmount,
  });

  /// Auto-calculate totalAmount as qty * rate
  factory InvoiceLineItem.create({
    required String sacCode,
    required String description,
    required String unit,
    required double qty,
    required double rate,
  }) {
    return InvoiceLineItem(
      sacCode: sacCode,
      description: description,
      unit: unit,
      qty: qty,
      rate: rate,
      totalAmount: qty * rate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sacCode': sacCode,
      'description': description,
      'unit': unit,
      'qty': qty,
      'rate': rate,
      'totalAmount': totalAmount,
    };
  }

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItem(
      sacCode: map['sacCode'] as String? ?? '',
      description: map['description'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      qty: (map['qty'] as num).toDouble(),
      rate: (map['rate'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
    );
  }

  @override
  List<Object> get props => [sacCode, description, unit, qty, rate, totalAmount];
}
