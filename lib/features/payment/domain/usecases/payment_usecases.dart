import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/payment/domain/entities/payment.dart';
import 'package:vrs_transport_manager/features/payment/domain/repositories/payment_repository.dart';

class GetPaymentsUseCase {
  final PaymentRepository _repository;
  GetPaymentsUseCase(this._repository);

  Future<Either<Failure, List<Payment>>> call() {
    return _repository.getPayments();
  }
}

class GetPaymentsForDateRangeUseCase {
  final PaymentRepository _repository;
  GetPaymentsForDateRangeUseCase(this._repository);

  Future<Either<Failure, List<Payment>>> call(
    DateTime weekStart,
    DateTime weekEnd,
  ) {
    return _repository.getPaymentsForDateRange(weekStart, weekEnd);
  }
}

class CreatePaymentUseCase {
  final PaymentRepository _repository;
  CreatePaymentUseCase(this._repository);

  Future<Either<Failure, String>> call(Payment payment) {
    return _repository.createPayment(payment);
  }
}

class DeletePaymentUseCase {
  final PaymentRepository _repository;
  DeletePaymentUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) {
    return _repository.deletePayment(id);
  }
}
