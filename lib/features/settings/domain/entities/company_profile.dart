import 'package:equatable/equatable.dart';

class CompanyProfile extends Equatable {
  final String companyName;
  final String gstin;
  final String phone1;
  final String phone2;
  final String email;
  final String address;
  final String tagline;
  final String bankName;
  final String bankBranch;
  final String accountNo;
  final String ifscCode;
  final String? logoBase64;
  final String? signatureBase64;

  const CompanyProfile({
    required this.companyName,
    required this.gstin,
    required this.phone1,
    required this.phone2,
    required this.email,
    required this.address,
    required this.tagline,
    required this.bankName,
    required this.bankBranch,
    required this.accountNo,
    required this.ifscCode,
    this.logoBase64,
    this.signatureBase64,
  });

  static const empty = CompanyProfile(
    companyName: '',
    gstin: '',
    phone1: '',
    phone2: '',
    email: '',
    address: '',
    tagline: '',
    bankName: '',
    bankBranch: '',
    accountNo: '',
    ifscCode: '',
  );

  bool get isEmpty => companyName.isEmpty;

  CompanyProfile copyWith({
    String? companyName,
    String? gstin,
    String? phone1,
    String? phone2,
    String? email,
    String? address,
    String? tagline,
    String? bankName,
    String? bankBranch,
    String? accountNo,
    String? ifscCode,
    String? logoBase64,
    String? signatureBase64,
    bool clearLogo = false,
    bool clearSignature = false,
  }) {
    return CompanyProfile(
      companyName: companyName ?? this.companyName,
      gstin: gstin ?? this.gstin,
      phone1: phone1 ?? this.phone1,
      phone2: phone2 ?? this.phone2,
      email: email ?? this.email,
      address: address ?? this.address,
      tagline: tagline ?? this.tagline,
      bankName: bankName ?? this.bankName,
      bankBranch: bankBranch ?? this.bankBranch,
      accountNo: accountNo ?? this.accountNo,
      ifscCode: ifscCode ?? this.ifscCode,
      logoBase64: clearLogo ? null : (logoBase64 ?? this.logoBase64),
      signatureBase64: clearSignature
          ? null
          : (signatureBase64 ?? this.signatureBase64),
    );
  }

  @override
  List<Object?> get props => [
        companyName,
        gstin,
        phone1,
        phone2,
        email,
        address,
        tagline,
        bankName,
        bankBranch,
        accountNo,
        ifscCode,
        logoBase64,
        signatureBase64,
      ];
}
