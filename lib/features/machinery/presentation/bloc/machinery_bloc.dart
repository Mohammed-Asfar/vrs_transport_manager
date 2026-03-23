import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vrs_transport_manager/features/machinery/domain/repositories/machinery_repository.dart';
import 'package:vrs_transport_manager/features/machinery/domain/usecases/machinery_usecases.dart';
import 'machinery_event.dart';
import 'machinery_state.dart';

class MachineryBloc extends Bloc<MachineryEvent, MachineryState> {
  final GetMachineryRecordsUseCase _getRecords;
  final CreateMachineryRecordUseCase _createRecord;
  final UpdateMachineryRecordUseCase _updateRecord;
  final DeleteMachineryRecordUseCase _deleteRecord;
  final SearchMachineryRecordsUseCase _searchRecords;
  final MachineryRepository _repository;
  StreamSubscription? _recordsSubscription;

  MachineryBloc({
    required GetMachineryRecordsUseCase getRecords,
    required CreateMachineryRecordUseCase createRecord,
    required UpdateMachineryRecordUseCase updateRecord,
    required DeleteMachineryRecordUseCase deleteRecord,
    required SearchMachineryRecordsUseCase searchRecords,
    required MachineryRepository repository,
  })  : _getRecords = getRecords,
        _createRecord = createRecord,
        _updateRecord = updateRecord,
        _deleteRecord = deleteRecord,
        _searchRecords = searchRecords,
        _repository = repository,
        super(const MachineryInitial()) {
    on<MachineryLoadRecords>(_onLoadRecords);
    on<MachineryRecordsUpdated>(_onRecordsUpdated);
    on<MachineryCreateRecord>(_onCreateRecord);
    on<MachineryUpdateRecord>(_onUpdateRecord);
    on<MachineryDeleteRecord>(_onDeleteRecord);
    on<MachinerySearchRecords>(_onSearchRecords);
    on<MachineryClearSearch>(_onClearSearch);
  }

  Future<void> _onLoadRecords(
    MachineryLoadRecords event,
    Emitter<MachineryState> emit,
  ) async {
    emit(const MachineryLoading());

    final result = await _getRecords();
    result.fold(
      (failure) => emit(MachineryError(failure.message)),
      (records) => emit(MachineryLoaded(records: records)),
    );

    await _recordsSubscription?.cancel();
    _recordsSubscription = _repository.watchRecords().listen(
      (records) => add(MachineryRecordsUpdated(records)),
      onError: (_) {},
    );
  }

  void _onRecordsUpdated(
    MachineryRecordsUpdated event,
    Emitter<MachineryState> emit,
  ) {
    final currentState = state;
    if (currentState is MachineryLoaded && currentState.isSearchResult) {
      return;
    }
    emit(MachineryLoaded(records: event.records));
  }

  Future<void> _onCreateRecord(
    MachineryCreateRecord event,
    Emitter<MachineryState> emit,
  ) async {
    emit(const MachineryLoading());
    final result = await _createRecord(event.record);
    result.fold(
      (failure) => emit(MachineryError(failure.message)),
      (_) => emit(const MachineryOperationSuccess('Record created successfully')),
    );
  }

  Future<void> _onUpdateRecord(
    MachineryUpdateRecord event,
    Emitter<MachineryState> emit,
  ) async {
    emit(const MachineryLoading());
    final result = await _updateRecord(event.record);
    result.fold(
      (failure) => emit(MachineryError(failure.message)),
      (_) => emit(const MachineryOperationSuccess('Record updated successfully')),
    );
  }

  Future<void> _onDeleteRecord(
    MachineryDeleteRecord event,
    Emitter<MachineryState> emit,
  ) async {
    emit(const MachineryLoading());
    final result = await _deleteRecord(event.id);
    result.fold(
      (failure) => emit(MachineryError(failure.message)),
      (_) => emit(const MachineryOperationSuccess('Record deleted successfully')),
    );
    if (result.isRight()) {
      final records = await _getRecords();
      records.fold(
        (_) {},
        (data) => emit(MachineryLoaded(records: data)),
      );
    }
  }

  Future<void> _onSearchRecords(
    MachinerySearchRecords event,
    Emitter<MachineryState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      add(const MachineryLoadRecords());
      return;
    }

    emit(const MachineryLoading());
    final result = await _searchRecords(event.query);
    result.fold(
      (failure) => emit(MachineryError(failure.message)),
      (records) => emit(MachineryLoaded(
        records: records,
        isSearchResult: true,
        searchQuery: event.query,
      )),
    );
  }

  Future<void> _onClearSearch(
    MachineryClearSearch event,
    Emitter<MachineryState> emit,
  ) async {
    add(const MachineryLoadRecords());
  }

  @override
  Future<void> close() {
    _recordsSubscription?.cancel();
    return super.close();
  }
}
