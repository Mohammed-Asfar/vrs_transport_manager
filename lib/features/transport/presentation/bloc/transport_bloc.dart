import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vrs_transport_manager/features/transport/domain/usecases/transport_usecases.dart';
import 'transport_event.dart';
import 'transport_state.dart';

class TransportBloc extends Bloc<TransportEvent, TransportState> {
  final GetRecordsUseCase _getRecords;
  final CreateRecordUseCase _createRecord;
  final UpdateRecordUseCase _updateRecord;
  final DeleteRecordUseCase _deleteRecord;
  final SearchRecordsUseCase _searchRecords;

  TransportBloc({
    required GetRecordsUseCase getRecords,
    required CreateRecordUseCase createRecord,
    required UpdateRecordUseCase updateRecord,
    required DeleteRecordUseCase deleteRecord,
    required SearchRecordsUseCase searchRecords,
  })  : _getRecords = getRecords,
        _createRecord = createRecord,
        _updateRecord = updateRecord,
        _deleteRecord = deleteRecord,
        _searchRecords = searchRecords,
        super(const TransportInitial()) {
    on<TransportLoadRecords>(_onLoadRecords);
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
    final result = await _getRecords();
    result.fold(
      (failure) => emit(TransportError(failure.message)),
      (records) => emit(TransportLoaded(records: records)),
    );
  }

  Future<void> _onCreateRecord(
    TransportCreateRecord event,
    Emitter<TransportState> emit,
  ) async {
    emit(const TransportLoading());
    final result = await _createRecord(event.record);
    await result.fold(
      (failure) async => emit(TransportError(failure.message)),
      (_) async {
        emit(const TransportOperationSuccess('Record created successfully'));
        // Reload records
        final loadResult = await _getRecords();
        loadResult.fold(
          (failure) => emit(TransportError(failure.message)),
          (records) => emit(TransportLoaded(records: records)),
        );
      },
    );
  }

  Future<void> _onUpdateRecord(
    TransportUpdateRecord event,
    Emitter<TransportState> emit,
  ) async {
    emit(const TransportLoading());
    final result = await _updateRecord(event.record);
    await result.fold(
      (failure) async => emit(TransportError(failure.message)),
      (_) async {
        emit(const TransportOperationSuccess('Record updated successfully'));
        final loadResult = await _getRecords();
        loadResult.fold(
          (failure) => emit(TransportError(failure.message)),
          (records) => emit(TransportLoaded(records: records)),
        );
      },
    );
  }

  Future<void> _onDeleteRecord(
    TransportDeleteRecord event,
    Emitter<TransportState> emit,
  ) async {
    emit(const TransportLoading());
    final result = await _deleteRecord(event.id);
    await result.fold(
      (failure) async => emit(TransportError(failure.message)),
      (_) async {
        emit(const TransportOperationSuccess('Record deleted successfully'));
        final loadResult = await _getRecords();
        loadResult.fold(
          (failure) => emit(TransportError(failure.message)),
          (records) => emit(TransportLoaded(records: records)),
        );
      },
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
}
