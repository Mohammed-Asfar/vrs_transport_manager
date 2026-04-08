import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/exceptions.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/client/data/datasources/client_remote_datasource.dart';
import 'package:vrs_transport_manager/features/client/data/models/client_model.dart';
import 'package:vrs_transport_manager/features/client/domain/entities/client.dart';
import 'package:vrs_transport_manager/features/client/domain/repositories/client_repository.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientRemoteDatasource _datasource;

  ClientRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<Client>>> getClients() async {
    try {
      final clients = await _datasource.getClients();
      return Right(clients);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Client>> createClient(Client client) async {
    try {
      final model = ClientModel.fromEntity(client);
      final id = await _datasource.createClient(model);
      return Right(client.copyWith(id: id));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
