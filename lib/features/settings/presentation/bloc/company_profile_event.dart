import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/settings/domain/entities/company_profile.dart';

sealed class CompanyProfileEvent extends Equatable {
  const CompanyProfileEvent();

  @override
  List<Object?> get props => [];
}

class CompanyProfileLoad extends CompanyProfileEvent {
  const CompanyProfileLoad();
}

class CompanyProfileSave extends CompanyProfileEvent {
  final CompanyProfile profile;
  const CompanyProfileSave(this.profile);

  @override
  List<Object?> get props => [profile];
}
