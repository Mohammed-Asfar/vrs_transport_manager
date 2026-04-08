import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/exceptions.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/invoice/data/datasources/invoice_remote_datasource.dart';
import 'package:vrs_transport_manager/features/invoice/data/models/invoice_record_model.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';
import 'package:vrs_transport_manager/features/invoice/domain/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDatasource _datasource;

  InvoiceRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<InvoiceRecord>>> getInvoices() async {
    try {
      final invoices = await _datasource.getInvoices();
      return Right(invoices);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<List<InvoiceRecord>> watchInvoices() {
    return _datasource.watchInvoices();
  }

  @override
  Future<Either<Failure, InvoiceRecord>> getInvoiceById(String id) async {
    try {
      final invoice = await _datasource.getInvoiceById(id);
      return Right(invoice);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> createInvoice(InvoiceRecord record) async {
    try {
      final model = InvoiceRecordModel.fromEntity(record);
      final id = await _datasource.createInvoice(model);
      return Right(id);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateInvoice(InvoiceRecord record) async {
    try {
      final model = InvoiceRecordModel.fromEntity(record);
      await _datasource.updateInvoice(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    try {
      await _datasource.deleteInvoice(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceRecord>>> searchInvoices(
      String query) async {
    try {
      final results = await _datasource.searchInvoices(query);
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> previewNextInvoiceNumber(DateTime date) async {
    try {
      final number = await _datasource.previewNextInvoiceNumber(date);
      return Right(number);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> commitInvoiceNumber(DateTime date) async {
    try {
      final number = await _datasource.commitInvoiceNumber(date);
      return Right(number);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
