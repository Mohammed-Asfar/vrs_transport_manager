import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String? id;
  final String transporterName;
  final double amount;
  final DateTime paymentDate;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final String remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  const Payment({
    this.id,
    required this.transporterName,
    required this.amount,
    required this.paymentDate,
    required this.weekStartDate,
    required this.weekEndDate,
    this.remarks = '',
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// Normalized name for case-insensitive matching
  String get transporterNameNormalized => transporterName.trim().toLowerCase();

  Payment copyWith({
    String? id,
    String? transporterName,
    double? amount,
    DateTime? paymentDate,
    DateTime? weekStartDate,
    DateTime? weekEndDate,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Payment(
      id: id ?? this.id,
      transporterName: transporterName ?? this.transporterName,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weekEndDate: weekEndDate ?? this.weekEndDate,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        transporterName,
        amount,
        paymentDate,
        weekStartDate,
        weekEndDate,
        remarks,
        createdAt,
        updatedAt,
        createdBy,
      ];
}
