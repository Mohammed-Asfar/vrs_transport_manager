import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/machinery_record.dart';
import 'package:vrs_transport_manager/features/machinery/domain/repositories/machinery_repository.dart';

class GetMachineryRecordsUseCase {
  final MachineryRepository _repository;
  GetMachineryRecordsUseCase(this._repository);

  Future<Either<Failure, List<MachineryRecord>>> call() {
    return _repository.getRecords();
  }
}

class GetMachineryRecordByIdUseCase {
  final MachineryRepository _repository;
  GetMachineryRecordByIdUseCase(this._repository);

  Future<Either<Failure, MachineryRecord>> call(String id) {
    return _repository.getRecordById(id);
  }
}

class CreateMachineryRecordUseCase {
  final MachineryRepository _repository;
  CreateMachineryRecordUseCase(this._repository);

  Future<Either<Failure, String>> call(MachineryRecord record) {
    return _repository.createRecord(record);
  }
}

class UpdateMachineryRecordUseCase {
  final MachineryRepository _repository;
  UpdateMachineryRecordUseCase(this._repository);

  Future<Either<Failure, void>> call(MachineryRecord record) {
    return _repository.updateRecord(record);
  }
}

class DeleteMachineryRecordUseCase {
  final MachineryRepository _repository;
  DeleteMachineryRecordUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) {
    return _repository.deleteRecord(id);
  }
}

class SearchMachineryRecordsUseCase {
  final MachineryRepository _repository;
  SearchMachineryRecordsUseCase(this._repository);

  Future<Either<Failure, List<MachineryRecord>>> call(String query) {
    return _repository.searchRecords(query);
  }
}
