import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vrs_transport_manager/features/client/domain/usecases/client_usecases.dart';
import 'client_event.dart';
import 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final GetClientsUseCase _getClients;
  final CreateClientUseCase _createClient;

  ClientBloc({
    required GetClientsUseCase getClients,
    required CreateClientUseCase createClient,
  })  : _getClients = getClients,
        _createClient = createClient,
        super(const ClientInitial()) {
    on<ClientLoadAll>(_onLoadAll);
    on<ClientCreate>(_onCreate);
  }

  Future<void> _onLoadAll(
    ClientLoadAll event,
    Emitter<ClientState> emit,
  ) async {
    emit(const ClientLoading());
    final result = await _getClients();
    result.fold(
      (failure) => emit(ClientError(failure.message)),
      (clients) => emit(ClientLoaded(clients)),
    );
  }

  Future<void> _onCreate(
    ClientCreate event,
    Emitter<ClientState> emit,
  ) async {
    emit(const ClientLoading());
    final result = await _createClient(event.client);
    result.fold(
      (failure) => emit(ClientError(failure.message)),
      (client) => emit(ClientCreated(client)),
    );
  }
}
