import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vrs_transport_manager/core/constants/firestore_constants.dart';
import 'package:vrs_transport_manager/core/errors/exceptions.dart';
import 'package:vrs_transport_manager/features/payment/data/models/payment_model.dart';

class PaymentRemoteDatasource {
  final FirebaseFirestore _firestore;

  PaymentRemoteDatasource(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreConstants.payments);

  Future<List<PaymentModel>> getPayments() async {
    try {
      final snapshot = await _collection
          .orderBy(FirestoreConstants.paymentDate, descending: true)
          .get();
      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch payments: $e');
    }
  }

  Future<List<PaymentModel>> getPaymentsForDateRange(
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    try {
      final snapshot = await _collection
          .where(FirestoreConstants.weekStartDate,
              isEqualTo: Timestamp.fromDate(weekStart))
          .where(FirestoreConstants.weekEndDate,
              isEqualTo: Timestamp.fromDate(weekEnd))
          .get();
      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch payments for date range: $e');
    }
  }

  Future<String> createPayment(PaymentModel payment) async {
    try {
      final docRef = await _collection.add(payment.toFirestore());
      return docRef.id;
    } catch (e) {
      throw ServerException('Failed to create payment: $e');
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw ServerException('Failed to delete payment: $e');
    }
  }

  Stream<List<PaymentModel>> watchPayments() {
    return _collection
        .orderBy(FirestoreConstants.paymentDate, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc))
            .toList());
  }
}
