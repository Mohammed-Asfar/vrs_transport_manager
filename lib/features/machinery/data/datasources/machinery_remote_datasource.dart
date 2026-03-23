import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vrs_transport_manager/core/constants/firestore_constants.dart';
import 'package:vrs_transport_manager/core/errors/exceptions.dart';
import 'package:vrs_transport_manager/features/machinery/data/models/machinery_record_model.dart';

class MachineryRemoteDatasource {
  final FirebaseFirestore _firestore;

  MachineryRemoteDatasource(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreConstants.machineryRecords);

  Future<List<MachineryRecordModel>> getRecords() async {
    try {
      final snapshot = await _collection
          .orderBy(FirestoreConstants.date, descending: true)
          .get();
      return snapshot.docs
          .map((doc) => MachineryRecordModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch machinery records: $e');
    }
  }

  Stream<List<MachineryRecordModel>> watchRecords() {
    return _collection
        .orderBy(FirestoreConstants.date, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MachineryRecordModel.fromFirestore(doc))
            .toList());
  }

  Future<MachineryRecordModel> getRecordById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        throw const ServerException('Machinery record not found');
      }
      return MachineryRecordModel.fromFirestore(doc);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to fetch machinery record: $e');
    }
  }

  Future<String> createRecord(MachineryRecordModel record) async {
    try {
      final docRef = await _collection.add(record.toFirestore());
      return docRef.id;
    } catch (e) {
      throw ServerException('Failed to create machinery record: $e');
    }
  }

  Future<void> updateRecord(MachineryRecordModel record) async {
    try {
      if (record.id == null) {
        throw const ServerException('Record ID is required for update');
      }
      await _collection.doc(record.id).update(record.toFirestore());
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to update machinery record: $e');
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw ServerException('Failed to delete machinery record: $e');
    }
  }

  Future<List<MachineryRecordModel>> searchRecords(String query) async {
    try {
      final snapshot = await _collection
          .orderBy(FirestoreConstants.date, descending: true)
          .get();

      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => MachineryRecordModel.fromFirestore(doc))
          .where((record) {
        if (record.machineName.toLowerCase().contains(lowerQuery)) return true;
        if (record.machineNumber.toLowerCase().contains(lowerQuery)) {
          return true;
        }
        if (record.operatorName.toLowerCase().contains(lowerQuery)) return true;
        if (record.location.toLowerCase().contains(lowerQuery)) return true;
        return false;
      }).toList();
    } catch (e) {
      throw ServerException('Failed to search machinery records: $e');
    }
  }
}
