import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vrs_transport_manager/features/client/domain/entities/client.dart';

class ClientModel extends Client {
  const ClientModel({
    super.id,
    required super.companyName,
    required super.gstin,
    required super.address,
  });

  factory ClientModel.fromEntity(Client entity) {
    return ClientModel(
      id: entity.id,
      companyName: entity.companyName,
      gstin: entity.gstin,
      address: entity.address,
    );
  }

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ClientModel(
      id: doc.id,
      companyName: data['companyName'] as String? ?? '',
      gstin: data['gstin'] as String? ?? '',
      address: data['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'companyName': companyName,
      'gstin': gstin,
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
