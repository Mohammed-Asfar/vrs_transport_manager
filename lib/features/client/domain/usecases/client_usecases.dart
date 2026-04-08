import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/client/domain/entities/client.dart';
import 'package:vrs_transport_manager/features/client/domain/repositories/client_repository.dart';

class GetClientsUseCase {
  final ClientRepository _repository;
  GetClientsUseCase(this._repository);

  Future<Either<Failure, List<Client>>> call() {
    return _repository.getClients();
  }
}

class CreateClientUseCase {
  final ClientRepository _repository;
  CreateClientUseCase(this._repository);

  Future<Either<Failure, Client>> call(Client client) {
    return _repository.createClient(client);
  }
}
