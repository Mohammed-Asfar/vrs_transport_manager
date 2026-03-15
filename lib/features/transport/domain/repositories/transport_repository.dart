import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';

abstract class TransportRepository {
  /// Get all transport records, ordered by date descending
  Future<Either<Failure, List<TransportRecord>>> getRecords();

  /// Get a single record by ID
  Future<Either<Failure, TransportRecord>> getRecordById(String id);

  /// Create a new transport record
  Future<Either<Failure, String>> createRecord(TransportRecord record);

  /// Update an existing transport record
  Future<Either<Failure, void>> updateRecord(TransportRecord record);

  /// Delete a transport record
  Future<Either<Failure, void>> deleteRecord(String id);

  /// Search records by vehicle number, transporter, or location
  Future<Either<Failure, List<TransportRecord>>> searchRecords(String query);

  /// Watch all transport records in real-time
  Stream<List<TransportRecord>> watchRecords();
}
