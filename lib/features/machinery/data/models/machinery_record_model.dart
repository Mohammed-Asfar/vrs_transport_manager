import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/billing_mode.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/machinery_record.dart';

class MachineryRecordModel extends MachineryRecord {
  const MachineryRecordModel({
    super.id,
    required super.machineName,
    required super.machineNumber,
    required super.operatorName,
    required super.location,
    required super.billingMode,
    required super.date,
    super.startDate,
    super.endDate,
    required super.monthlyRent,
    required super.ratePerLoad,
    required super.totalLoads,
    required super.totalAmount,
    required super.diesel,
    required super.advance,
    required super.balance,
    super.remarks,
    super.createdAt,
    super.updatedAt,
    super.createdBy,
  });

  factory MachineryRecordModel.fromEntity(MachineryRecord entity) {
    return MachineryRecordModel(
      id: entity.id,
      machineName: entity.machineName,
      machineNumber: entity.machineNumber,
      operatorName: entity.operatorName,
      location: entity.location,
      billingMode: entity.billingMode,
      date: entity.date,
      startDate: entity.startDate,
      endDate: entity.endDate,
      monthlyRent: entity.monthlyRent,
      ratePerLoad: entity.ratePerLoad,
      totalLoads: entity.totalLoads,
      totalAmount: entity.totalAmount,
      diesel: entity.diesel,
      advance: entity.advance,
      balance: entity.balance,
      remarks: entity.remarks,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
    );
  }

  factory MachineryRecordModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    final billingModeStr = data['billingMode'] as String? ?? 'perLoad';
    final billingMode = billingModeStr == 'monthlyRent'
        ? BillingMode.monthlyRent
        : BillingMode.perLoad;

    return MachineryRecordModel(
      id: doc.id,
      machineName: data['machineName'] as String? ?? '',
      machineNumber: data['machineNumber'] as String? ?? '',
      operatorName: data['operatorName'] as String? ?? '',
      location: data['location'] as String? ?? '',
      billingMode: billingMode,
      date: (data['date'] as Timestamp).toDate(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      monthlyRent: (data['monthlyRent'] as num?)?.toDouble() ?? 0,
      ratePerLoad: (data['ratePerLoad'] as num?)?.toDouble() ?? 0,
      totalLoads: (data['totalLoads'] as num?)?.toInt() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      diesel: (data['diesel'] as num?)?.toDouble() ?? 0,
      advance: (data['advance'] as num?)?.toDouble() ?? 0,
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      remarks: data['remarks'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'machineName': machineName,
      'machineNumber': machineNumber,
      'operatorName': operatorName,
      'location': location,
      'billingMode': billingMode.name,
      'date': Timestamp.fromDate(date),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'monthlyRent': monthlyRent,
      'ratePerLoad': ratePerLoad,
      'totalLoads': totalLoads,
      'totalAmount': totalAmount,
      'diesel': diesel,
      'advance': advance,
      'balance': balance,
      'remarks': remarks,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
