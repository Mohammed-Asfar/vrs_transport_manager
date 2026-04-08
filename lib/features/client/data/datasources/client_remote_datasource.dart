import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vrs_transport_manager/core/errors/exceptions.dart';
import 'package:vrs_transport_manager/features/client/data/models/client_model.dart';

class ClientRemoteDatasource {
  final FirebaseFirestore _firestore;

  ClientRemoteDatasource(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('clients');

  Future<List<ClientModel>> getClients() async {
    try {
      final snapshot = await _collection.orderBy('companyName').get();
      return snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load clients: $e');
    }
  }

  Future<String> createClient(ClientModel model) async {
    try {
      final doc = await _collection.add(model.toFirestore());
      return doc.id;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create client: $e');
    }
  }
}
