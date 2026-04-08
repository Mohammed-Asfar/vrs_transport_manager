import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/exceptions.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/settings/data/datasources/company_profile_remote_datasource.dart';
import 'package:vrs_transport_manager/features/settings/data/models/company_profile_model.dart';
import 'package:vrs_transport_manager/features/settings/domain/entities/company_profile.dart';
import 'package:vrs_transport_manager/features/settings/domain/repositories/company_profile_repository.dart';

class CompanyProfileRepositoryImpl implements CompanyProfileRepository {
  final CompanyProfileRemoteDatasource _datasource;

  CompanyProfileRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, CompanyProfile?>> getProfile() async {
    try {
      final profile = await _datasource.getProfile();
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> saveProfile(CompanyProfile profile) async {
    try {
      final model = CompanyProfileModel.fromEntity(profile);
      await _datasource.saveProfile(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
