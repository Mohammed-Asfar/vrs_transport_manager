import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/settings/domain/entities/company_profile.dart';

abstract class CompanyProfileRepository {
  Future<Either<Failure, CompanyProfile?>> getProfile();
  Future<Either<Failure, void>> saveProfile(CompanyProfile profile);
}
