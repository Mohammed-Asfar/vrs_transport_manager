import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vrs_transport_manager/features/settings/domain/entities/company_profile.dart';

class CompanyProfileModel extends CompanyProfile {
  const CompanyProfileModel({
    required super.companyName,
    required super.gstin,
    required super.phone1,
    required super.phone2,
    required super.email,
    required super.address,
    required super.tagline,
    required super.bankName,
    required super.bankBranch,
    required super.accountNo,
    required super.ifscCode,
    super.logoBase64,
    super.signatureBase64,
  });

  factory CompanyProfileModel.fromEntity(CompanyProfile entity) {
    return CompanyProfileModel(
      companyName: entity.companyName,
      gstin: entity.gstin,
      phone1: entity.phone1,
      phone2: entity.phone2,
      email: entity.email,
      address: entity.address,
      tagline: entity.tagline,
      bankName: entity.bankName,
      bankBranch: entity.bankBranch,
      accountNo: entity.accountNo,
      ifscCode: entity.ifscCode,
      logoBase64: entity.logoBase64,
      signatureBase64: entity.signatureBase64,
    );
  }

  factory CompanyProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CompanyProfileModel(
      companyName: data['companyName'] as String? ?? '',
      gstin: data['gstin'] as String? ?? '',
      phone1: data['phone1'] as String? ?? '',
      phone2: data['phone2'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
      tagline: data['tagline'] as String? ?? '',
      bankName: data['bankName'] as String? ?? '',
      bankBranch: data['bankBranch'] as String? ?? '',
      accountNo: data['accountNo'] as String? ?? '',
      ifscCode: data['ifscCode'] as String? ?? '',
      logoBase64: data['logoBase64'] as String?,
      signatureBase64: data['signatureBase64'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'companyName': companyName,
      'gstin': gstin,
      'phone1': phone1,
      'phone2': phone2,
      'email': email,
      'address': address,
      'tagline': tagline,
      'bankName': bankName,
      'bankBranch': bankBranch,
      'accountNo': accountNo,
      'ifscCode': ifscCode,
      'logoBase64': logoBase64,
      'signatureBase64': signatureBase64,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
