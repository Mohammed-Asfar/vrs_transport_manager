import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';

abstract class InvoiceRepository {
  Future<Either<Failure, List<InvoiceRecord>>> getInvoices();
  Stream<List<InvoiceRecord>> watchInvoices();
  Future<Either<Failure, InvoiceRecord>> getInvoiceById(String id);
  Future<Either<Failure, String>> createInvoice(InvoiceRecord record);
  Future<Either<Failure, void>> updateInvoice(InvoiceRecord record);
  Future<Either<Failure, void>> deleteInvoice(String id);
  Future<Either<Failure, List<InvoiceRecord>>> searchInvoices(String query);
  Future<Either<Failure, String>> previewNextInvoiceNumber(DateTime date);
  Future<Either<Failure, String>> commitInvoiceNumber(DateTime date);
}
