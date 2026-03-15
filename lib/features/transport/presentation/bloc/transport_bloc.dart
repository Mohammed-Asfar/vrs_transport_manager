import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vrs_transport_manager/features/transport/domain/repositories/transport_repository.dart';
import 'package:vrs_transport_manager/features/transport/domain/usecases/transport_usecases.dart';
import 'transport_event.dart';
import 'transport_state.dart';

class TransportBloc extends Bloc<TransportEvent, TransportState> {
  final GetRecordsUseCase _getRecords;
  final CreateRecordUseCase _createRecord;
  final UpdateRecordUseCase _updateRecord;
  final DeleteRecordUseCase _deleteRecord;
  final SearchRecordsUseCase _searchRecords;
  final TransportRepository _repository;
  StreamSubscription? _recordsSubscription;

  TransportBloc({
    required GetRecordsUseCase getRecords,
    required CreateRecordUseCase createRecord,
    required UpdateRecordUseCase updateRecord,
    required DeleteRecordUseCase deleteRecord,
    required SearchRecordsUseCase searchRecords,
    required TransportRepository repository,
  })  : _getRecords = getRecords,
        _createRecord = createRecord,
        _updateRecord = updateRecord,
        _deleteRecord = deleteRecord,
        _searchRecords = searchRecords,
        _repository = repository,
        super(const TransportInitial()) {
    on<TransportLoadRecords>(_onLoadRecords);
    on<TransportRecordsUpdated>(_onRecordsUpdated);
    on<TransportCreateRecord>(_onCreateRecord);
    on<TransportUpdateRecord>(_onUpdateRecord);
    on<TransportDeleteRecord>(_onDeleteRecord);
    on<TransportSearchRecords>(_onSearchRecords);
    on<TransportClearSearch>(_onClearSearch);
  }

  Future<void> _onLoadRecords(
    TransportLoadRecords event,
    Emitter<TransportState> emit,
  ) async {
    emit(const TransportLoading());

    // Fetch initial data
    final result = await _getRecords();
    result.fold(
      (failure) => emit(TransportError(failure.message)),
      (records) => emit(TransportLoaded(records: records)),
    );

    // Start listening for real-time updates
    await _recordsSubscription?.cancel();
    _recordsSubscription = _repository.watchRecords().listen(
      (records) => add(TransportRecordsUpdated(records)),
      onError: (_) {}, // Silently handle stream errors; initial fetch already loaded data
    );
  }

  void _onRecordsUpdated(
    TransportRecordsUpdated event,
    Emitter<TransportState> emit,
  ) {
    // Only update if not in a search state
    final currentState = state;
    if (currentState is TransportLoaded && currentState.isSearchResult) {
      return;
    }
    emit(TransportLoaded(records: event.records));
  }

  Future<void> _onCreateRecord(
    TransportCreateRecord event,
    Emitter<TransportState> emit,
  ) async {
    emit(const TransportLoading());
    final result = await _createRecord(event.record);
    result.fold(
      (failure) => emit(TransportError(failure.message)),
      (_) => emit(const TransportOperationSuccess('Record created successfully')),
    );
    // Stream will auto-update the list
  }

  Future<void> _onUpdateRecord(
    TransportUpdateRecord event,
    Emitter<TransportState> emit,
  ) async {
    emit(const TransportLoading());
    final result = await _updateRecord(event.record);
    result.fold(
      (failure) => emit(TransportError(failure.message)),
      (_) => emit(const TransportOperationSuccess('Record updated successfully')),
    );
  }

  Future<void> _onDeleteRecord(
    TransportDeleteRecord event,
    Emitter<TransportState> emit,
  ) async {
    emit(const TransportLoading());
    final result = await _deleteRecord(event.id);
    result.fold(
      (failure) => emit(TransportError(failure.message)),
      (_) => emit(const TransportOperationSuccess('Record deleted successfully')),
    );
  }

  Future<void> _onSearchRecords(
    TransportSearchRecords event,
    Emitter<TransportState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      add(const TransportLoadRecords());
      return;
    }

    emit(const TransportLoading());
    final result = await _searchRecords(event.query);
    result.fold(
      (failure) => emit(TransportError(failure.message)),
      (records) => emit(TransportLoaded(
        records: records,
        isSearchResult: true,
        searchQuery: event.query,
      )),
    );
  }

  Future<void> _onClearSearch(
    TransportClearSearch event,
    Emitter<TransportState> emit,
  ) async {
    add(const TransportLoadRecords());
  }

  @override
  Future<void> close() {
    _recordsSubscription?.cancel();
    return super.close();
  }
}
