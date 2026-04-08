import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vrs_transport_manager/core/errors/exceptions.dart';
import 'package:vrs_transport_manager/features/settings/data/models/company_profile_model.dart';

class CompanyProfileRemoteDatasource {
  final FirebaseFirestore _firestore;

  CompanyProfileRemoteDatasource(this._firestore);

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('company_profile').doc('profile');

  Future<CompanyProfileModel?> getProfile() async {
    try {
      final snapshot = await _doc.get();
      if (!snapshot.exists) return null;
      return CompanyProfileModel.fromFirestore(snapshot);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load company profile: $e');
    }
  }

  Future<void> saveProfile(CompanyProfileModel model) async {
    try {
      await _doc.set(model.toFirestore(), SetOptions(merge: true));
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to save company profile: $e');
    }
  }
}
