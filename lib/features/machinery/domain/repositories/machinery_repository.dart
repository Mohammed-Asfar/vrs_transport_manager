import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/machinery_record.dart';

abstract class MachineryRepository {
  Future<Either<Failure, List<MachineryRecord>>> getRecords();
  Future<Either<Failure, MachineryRecord>> getRecordById(String id);
  Future<Either<Failure, String>> createRecord(MachineryRecord record);
  Future<Either<Failure, void>> updateRecord(MachineryRecord record);
  Future<Either<Failure, void>> deleteRecord(String id);
  Future<Either<Failure, List<MachineryRecord>>> searchRecords(String query);
  Stream<List<MachineryRecord>> watchRecords();
}
