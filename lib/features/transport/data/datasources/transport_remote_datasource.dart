import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vrs_transport_manager/core/constants/firestore_constants.dart';
import 'package:vrs_transport_manager/core/errors/exceptions.dart';
import 'package:vrs_transport_manager/features/transport/data/models/transport_record_model.dart';

class TransportRemoteDatasource {
  final FirebaseFirestore _firestore;

  TransportRemoteDatasource(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreConstants.transportRecords);

  Future<List<TransportRecordModel>> getRecords() async {
    try {
      final snapshot = await _collection
          .orderBy(FirestoreConstants.date, descending: true)
          .get();
      return snapshot.docs
          .map((doc) => TransportRecordModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch records: $e');
    }
  }

  Future<TransportRecordModel> getRecordById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        throw const ServerException('Record not found');
      }
      return TransportRecordModel.fromFirestore(doc);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to fetch record: $e');
    }
  }

  Future<String> createRecord(TransportRecordModel record) async {
    try {
      final docRef = await _collection.add(record.toFirestore());
      return docRef.id;
    } catch (e) {
      throw ServerException('Failed to create record: $e');
    }
  }

  Future<void> updateRecord(TransportRecordModel record) async {
    try {
      if (record.id == null) {
        throw const ServerException('Record ID is required for update');
      }
      await _collection.doc(record.id).update(record.toFirestore());
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to update record: $e');
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw ServerException('Failed to delete record: $e');
    }
  }

  Future<List<TransportRecordModel>> searchRecords(String query) async {
    try {
      // Firestore doesn't support full-text search natively,
      // so we fetch all and filter client-side
      final snapshot = await _collection
          .orderBy(FirestoreConstants.date, descending: true)
          .get();

      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => TransportRecordModel.fromFirestore(doc))
          .where((record) {
        // Search in location
        if (record.location.toLowerCase().contains(lowerQuery)) return true;

        // Search in trips (vehicle no, transporter)
        for (final trip in record.trips) {
          if (trip.vehicleNo.toLowerCase().contains(lowerQuery)) return true;
          if (trip.transporter.toLowerCase().contains(lowerQuery)) return true;
        }
        return false;
      }).toList();
    } catch (e) {
      throw ServerException('Failed to search records: $e');
    }
  }
}
