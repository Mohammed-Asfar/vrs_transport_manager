import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/settings/domain/entities/company_profile.dart';
import 'package:vrs_transport_manager/features/settings/domain/repositories/company_profile_repository.dart';

class GetCompanyProfileUseCase {
  final CompanyProfileRepository _repository;
  GetCompanyProfileUseCase(this._repository);

  Future<Either<Failure, CompanyProfile?>> call() {
    return _repository.getProfile();
  }
}

class SaveCompanyProfileUseCase {
  final CompanyProfileRepository _repository;
  SaveCompanyProfileUseCase(this._repository);

  Future<Either<Failure, void>> call(CompanyProfile profile) {
    return _repository.saveProfile(profile);
  }
}
