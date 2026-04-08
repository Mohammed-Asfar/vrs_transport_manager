import 'package:equatable/equatable.dart';

class Client extends Equatable {
  final String? id;
  final String companyName;
  final String gstin;
  final String address;

  const Client({
    this.id,
    required this.companyName,
    required this.gstin,
    required this.address,
  });

  Client copyWith({
    String? id,
    String? companyName,
    String? gstin,
    String? address,
  }) {
    return Client(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'gstin': gstin,
      'address': address,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      companyName: map['companyName'] as String? ?? '',
      gstin: map['gstin'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, companyName, gstin, address];
}
