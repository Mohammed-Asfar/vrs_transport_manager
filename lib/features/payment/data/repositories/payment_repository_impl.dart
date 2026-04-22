import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/exceptions.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:vrs_transport_manager/features/payment/data/models/payment_model.dart';
import 'package:vrs_transport_manager/features/payment/domain/entities/payment.dart';
import 'package:vrs_transport_manager/features/payment/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDatasource _datasource;

  PaymentRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<Payment>>> getPayments() async {
    try {
      final payments = await _datasource.getPayments();
      return Right(payments);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsForDateRange(
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    try {
      final payments =
          await _datasource.getPaymentsForDateRange(weekStart, weekEnd);
      return Right(payments);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> createPayment(Payment payment) async {
    try {
      final model = PaymentModel.fromEntity(payment);
      final id = await _datasource.createPayment(model);
      return Right(id);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deletePayment(String id) async {
    try {
      await _datasource.deletePayment(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<List<Payment>> watchPayments() {
    return _datasource.watchPayments();
  }
}
