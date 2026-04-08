import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';
import 'package:vrs_transport_manager/features/invoice/domain/repositories/invoice_repository.dart';

class GetInvoicesUseCase {
  final InvoiceRepository _repository;
  GetInvoicesUseCase(this._repository);

  Future<Either<Failure, List<InvoiceRecord>>> call() {
    return _repository.getInvoices();
  }
}

class GetInvoiceByIdUseCase {
  final InvoiceRepository _repository;
  GetInvoiceByIdUseCase(this._repository);

  Future<Either<Failure, InvoiceRecord>> call(String id) {
    return _repository.getInvoiceById(id);
  }
}

class CreateInvoiceUseCase {
  final InvoiceRepository _repository;
  CreateInvoiceUseCase(this._repository);

  Future<Either<Failure, String>> call(InvoiceRecord record) {
    return _repository.createInvoice(record);
  }
}

class UpdateInvoiceUseCase {
  final InvoiceRepository _repository;
  UpdateInvoiceUseCase(this._repository);

  Future<Either<Failure, void>> call(InvoiceRecord record) {
    return _repository.updateInvoice(record);
  }
}

class DeleteInvoiceUseCase {
  final InvoiceRepository _repository;
  DeleteInvoiceUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) {
    return _repository.deleteInvoice(id);
  }
}

class SearchInvoicesUseCase {
  final InvoiceRepository _repository;
  SearchInvoicesUseCase(this._repository);

  Future<Either<Failure, List<InvoiceRecord>>> call(String query) {
    return _repository.searchInvoices(query);
  }
}

class PreviewInvoiceNumberUseCase {
  final InvoiceRepository _repository;
  PreviewInvoiceNumberUseCase(this._repository);

  Future<Either<Failure, String>> call(DateTime date) {
    return _repository.previewNextInvoiceNumber(date);
  }
}

class CommitInvoiceNumberUseCase {
  final InvoiceRepository _repository;
  CommitInvoiceNumberUseCase(this._repository);

  Future<Either<Failure, String>> call(DateTime date) {
    return _repository.commitInvoiceNumber(date);
  }
}
