import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/settings/domain/entities/company_profile.dart';

sealed class CompanyProfileState extends Equatable {
  const CompanyProfileState();

  @override
  List<Object?> get props => [];
}

class CompanyProfileInitial extends CompanyProfileState {
  const CompanyProfileInitial();
}

class CompanyProfileLoading extends CompanyProfileState {
  const CompanyProfileLoading();
}

class CompanyProfileLoaded extends CompanyProfileState {
  final CompanyProfile profile;
  const CompanyProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class CompanyProfileSaved extends CompanyProfileState {
  final CompanyProfile profile;
  const CompanyProfileSaved(this.profile);

  @override
  List<Object?> get props => [profile];
}

class CompanyProfileError extends CompanyProfileState {
  final String message;
  const CompanyProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
