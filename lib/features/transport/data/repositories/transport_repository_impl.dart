import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/exceptions.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/transport/data/datasources/transport_remote_datasource.dart';
import 'package:vrs_transport_manager/features/transport/data/models/transport_record_model.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';
import 'package:vrs_transport_manager/features/transport/domain/repositories/transport_repository.dart';

class TransportRepositoryImpl implements TransportRepository {
  final TransportRemoteDatasource _datasource;

  TransportRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<TransportRecord>>> getRecords() async {
    try {
      final records = await _datasource.getRecords();
      return Right(records);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, TransportRecord>> getRecordById(String id) async {
    try {
      final record = await _datasource.getRecordById(id);
      return Right(record);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> createRecord(TransportRecord record) async {
    try {
      final model = TransportRecordModel.fromEntity(record);
      final id = await _datasource.createRecord(model);
      return Right(id);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateRecord(TransportRecord record) async {
    try {
      final model = TransportRecordModel.fromEntity(record);
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
  Future<Either<Failure, List<TransportRecord>>> searchRecords(
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
  Stream<List<TransportRecord>> watchRecords() {
    return _datasource.watchRecords();
  }
}
