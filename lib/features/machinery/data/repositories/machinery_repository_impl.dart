import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/exceptions.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/machinery/data/datasources/machinery_remote_datasource.dart';
import 'package:vrs_transport_manager/features/machinery/data/models/machinery_record_model.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/machinery_record.dart';
import 'package:vrs_transport_manager/features/machinery/domain/repositories/machinery_repository.dart';

class MachineryRepositoryImpl implements MachineryRepository {
  final MachineryRemoteDatasource _datasource;

  MachineryRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<MachineryRecord>>> getRecords() async {
    try {
      final records = await _datasource.getRecords();
      return Right(records);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, MachineryRecord>> getRecordById(String id) async {
    try {
      final record = await _datasource.getRecordById(id);
      return Right(record);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> createRecord(MachineryRecord record) async {
    try {
      final model = MachineryRecordModel.fromEntity(record);
      final id = await _datasource.createRecord(model);
      return Right(id);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateRecord(MachineryRecord record) async {
    try {
      final model = MachineryRecordModel.fromEntity(record);
      await _datasource.updateRecord(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecord(String id) async {
    try {
      await _datasource.deleteRecord(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<MachineryRecord>>> searchRecords(
    String query,
  ) async {
    try {
      final records = await _datasource.searchRecords(query);
      return Right(records);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<List<MachineryRecord>> watchRecords() {
    return _datasource.watchRecords();
  }
}
