import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/client/domain/entities/client.dart';

sealed class ClientState extends Equatable {
  const ClientState();

  @override
  List<Object?> get props => [];
}

class ClientInitial extends ClientState {
  const ClientInitial();
}

class ClientLoading extends ClientState {
  const ClientLoading();
}

class ClientLoaded extends ClientState {
  final List<Client> clients;
  const ClientLoaded(this.clients);

  @override
  List<Object?> get props => [clients];
}

class ClientCreated extends ClientState {
  final Client client;
  const ClientCreated(this.client);

  @override
  List<Object?> get props => [client];
}

class ClientError extends ClientState {
  final String message;
  const ClientError(this.message);

  @override
  List<Object?> get props => [message];
}
