import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/client/domain/entities/client.dart';

abstract class ClientRepository {
  Future<Either<Failure, List<Client>>> getClients();
  Future<Either<Failure, Client>> createClient(Client client);
}
