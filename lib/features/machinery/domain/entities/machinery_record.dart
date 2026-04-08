import 'package:equatable/equatable.dart';
import 'billing_mode.dart';

class MachineryRecord extends Equatable {
  final String? id;
  final String machineName;
  final String machineNumber;
  final String operatorName;
  final String location;
  final BillingMode billingMode;
  final DateTime date;
  final DateTime? startDate;
  final DateTime? endDate;
  final double monthlyRent;
  final double ratePerLoad;
  final int totalLoads;
  final double totalAmount;
  final double diesel;
  final double advance;
  final double balance;
  final String remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  const MachineryRecord({
    this.id,
    required this.machineName,
    required this.machineNumber,
    required this.operatorName,
    required this.location,
    required this.billingMode,
    required this.date,
    this.startDate,
    this.endDate,
    required this.monthlyRent,
    required this.ratePerLoad,
    required this.totalLoads,
    required this.totalAmount,
    required this.diesel,
    required this.advance,
    required this.balance,
    this.remarks = '',
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// Auto-calculate totals based on billing mode
  factory MachineryRecord.create({
    String? id,
    required String machineName,
    required String machineNumber,
    required String operatorName,
    required String location,
    required BillingMode billingMode,
    required DateTime date,
    DateTime? startDate,
    DateTime? endDate,
    double monthlyRent = 0,
    double ratePerLoad = 0,
    int totalLoads = 0,
    required double diesel,
    required double advance,
    String remarks = '',
    String? createdBy,
  }) {
    final totalAmount = billingMode == BillingMode.monthlyRent
        ? monthlyRent
        : ratePerLoad * totalLoads;
    final balance = totalAmount - advance;

    return MachineryRecord(
      id: id,
      machineName: machineName,
      machineNumber: machineNumber,
      operatorName: operatorName,
      location: location,
      billingMode: billingMode,
      date: date,
      startDate: startDate,
      endDate: endDate,
      monthlyRent: monthlyRent,
      ratePerLoad: ratePerLoad,
      totalLoads: totalLoads,
      totalAmount: totalAmount,
      diesel: diesel,
      advance: advance,
      balance: balance,
      remarks: remarks,
      createdBy: createdBy,
    );
  }

  MachineryRecord copyWith({
    String? id,
    String? machineName,
    String? machineNumber,
    String? operatorName,
    String? location,
    BillingMode? billingMode,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    double? monthlyRent,
    double? ratePerLoad,
    int? totalLoads,
    double? totalAmount,
    double? diesel,
    double? advance,
    double? balance,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return MachineryRecord(
      id: id ?? this.id,
      machineName: machineName ?? this.machineName,
      machineNumber: machineNumber ?? this.machineNumber,
      operatorName: operatorName ?? this.operatorName,
      location: location ?? this.location,
      billingMode: billingMode ?? this.billingMode,
      date: date ?? this.date,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      monthlyRent: monthlyRent ?? this.monthlyRent,
      ratePerLoad: ratePerLoad ?? this.ratePerLoad,
      totalLoads: totalLoads ?? this.totalLoads,
      totalAmount: totalAmount ?? this.totalAmount,
      diesel: diesel ?? this.diesel,
      advance: advance ?? this.advance,
      balance: balance ?? this.balance,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        machineName,
        machineNumber,
        operatorName,
        location,
        billingMode,
        date,
        startDate,
        endDate,
        monthlyRent,
        ratePerLoad,
        totalLoads,
        totalAmount,
        diesel,
        advance,
        balance,
        remarks,
        createdAt,
        updatedAt,
        createdBy,
      ];
}
