import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/client/domain/entities/client.dart';

sealed class ClientEvent extends Equatable {
  const ClientEvent();

  @override
  List<Object?> get props => [];
}

class ClientLoadAll extends ClientEvent {
  const ClientLoadAll();
}

class ClientCreate extends ClientEvent {
  final Client client;
  const ClientCreate(this.client);

  @override
  List<Object?> get props => [client];
}
