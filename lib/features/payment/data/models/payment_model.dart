import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vrs_transport_manager/features/payment/domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    super.id,
    required super.transporterName,
    required super.amount,
    required super.paymentDate,
    required super.weekStartDate,
    required super.weekEndDate,
    super.remarks,
    super.createdAt,
    super.updatedAt,
    super.createdBy,
  });

  factory PaymentModel.fromEntity(Payment entity) {
    return PaymentModel(
      id: entity.id,
      transporterName: entity.transporterName,
      amount: entity.amount,
      paymentDate: entity.paymentDate,
      weekStartDate: entity.weekStartDate,
      weekEndDate: entity.weekEndDate,
      remarks: entity.remarks,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
    );
  }

  factory PaymentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return PaymentModel(
      id: doc.id,
      transporterName: data['transporterName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      weekStartDate: (data['weekStartDate'] as Timestamp).toDate(),
      weekEndDate: (data['weekEndDate'] as Timestamp).toDate(),
      remarks: data['remarks'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'transporterName': transporterName,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'weekStartDate': Timestamp.fromDate(weekStartDate),
      'weekEndDate': Timestamp.fromDate(weekEndDate),
      'remarks': remarks,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
