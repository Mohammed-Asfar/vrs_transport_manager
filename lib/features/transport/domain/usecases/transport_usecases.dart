import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';
import 'package:vrs_transport_manager/features/transport/domain/repositories/transport_repository.dart';

class GetRecordsUseCase {
  final TransportRepository _repository;
  GetRecordsUseCase(this._repository);

  Future<Either<Failure, List<TransportRecord>>> call() {
    return _repository.getRecords();
  }
}

class GetRecordByIdUseCase {
  final TransportRepository _repository;
  GetRecordByIdUseCase(this._repository);

  Future<Either<Failure, TransportRecord>> call(String id) {
    return _repository.getRecordById(id);
  }
}

class CreateRecordUseCase {
  final TransportRepository _repository;
  CreateRecordUseCase(this._repository);

  Future<Either<Failure, String>> call(TransportRecord record) {
    return _repository.createRecord(record);
  }
}

class UpdateRecordUseCase {
  final TransportRepository _repository;
  UpdateRecordUseCase(this._repository);

  Future<Either<Failure, void>> call(TransportRecord record) {
    return _repository.updateRecord(record);
  }
}

class DeleteRecordUseCase {
  final TransportRepository _repository;
  DeleteRecordUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) {
    return _repository.deleteRecord(id);
  }
}

class SearchRecordsUseCase {
  final TransportRepository _repository;
  SearchRecordsUseCase(this._repository);

  Future<Either<Failure, List<TransportRecord>>> call(String query) {
    return _repository.searchRecords(query);
  }
}
