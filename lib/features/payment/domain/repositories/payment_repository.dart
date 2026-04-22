import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/payment/domain/entities/payment.dart';

abstract class PaymentRepository {
  /// Get all payments, ordered by payment date descending
  Future<Either<Failure, List<Payment>>> getPayments();

  /// Get payments for a specific date range (matches weekStartDate & weekEndDate)
  Future<Either<Failure, List<Payment>>> getPaymentsForDateRange(
    DateTime weekStart,
    DateTime weekEnd,
  );

  /// Create a new payment
  Future<Either<Failure, String>> createPayment(Payment payment);

  /// Delete a payment
  Future<Either<Failure, void>> deletePayment(String id);

  /// Watch all payments in real-time
  Stream<List<Payment>> watchPayments();
}
