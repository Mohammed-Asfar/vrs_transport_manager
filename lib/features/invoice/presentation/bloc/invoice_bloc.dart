import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';
import 'package:vrs_transport_manager/features/invoice/domain/repositories/invoice_repository.dart';
import 'package:vrs_transport_manager/features/invoice/domain/usecases/invoice_usecases.dart';
import 'invoice_event.dart';
import 'invoice_state.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final GetInvoicesUseCase _getInvoices;
  final CreateInvoiceUseCase _createInvoice;
  final UpdateInvoiceUseCase _updateInvoice;
  final DeleteInvoiceUseCase _deleteInvoice;
  final SearchInvoicesUseCase _searchInvoices;
  final InvoiceRepository _repository;

  StreamSubscription<List<InvoiceRecord>>? _recordsSubscription;

  InvoiceBloc({
    required GetInvoicesUseCase getInvoices,
    required CreateInvoiceUseCase createInvoice,
    required UpdateInvoiceUseCase updateInvoice,
    required DeleteInvoiceUseCase deleteInvoice,
    required SearchInvoicesUseCase searchInvoices,
    required InvoiceRepository repository,
  })  : _getInvoices = getInvoices,
        _createInvoice = createInvoice,
        _updateInvoice = updateInvoice,
        _deleteInvoice = deleteInvoice,
        _searchInvoices = searchInvoices,
        _repository = repository,
        super(const InvoiceInitial()) {
    on<InvoiceLoadRecords>(_onLoadRecords);
    on<InvoiceRecordsUpdated>(_onRecordsUpdated);
    on<InvoiceCreateRecord>(_onCreateRecord);
    on<InvoiceUpdateRecord>(_onUpdateRecord);
    on<InvoiceDeleteRecord>(_onDeleteRecord);
    on<InvoiceSearchRecords>(_onSearchRecords);
    on<InvoiceClearSearch>(_onClearSearch);
  }

  Future<void> _onLoadRecords(
    InvoiceLoadRecords event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(const InvoiceLoading());

    final result = await _getInvoices();
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (records) => emit(InvoiceLoaded(records: records)),
    );

    await _recordsSubscription?.cancel();
    _recordsSubscription = _repository.watchInvoices().listen(
          (records) => add(InvoiceRecordsUpdated(records)),
          onError: (_) {},
        );
  }

  void _onRecordsUpdated(
    InvoiceRecordsUpdated event,
    Emitter<InvoiceState> emit,
  ) {
    final currentState = state;
    if (currentState is InvoiceLoaded && currentState.isSearchResult) {
      return;
    }
    emit(InvoiceLoaded(records: event.records));
  }

  Future<void> _onCreateRecord(
    InvoiceCreateRecord event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(const InvoiceLoading());
    final result = await _createInvoice(event.record);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (_) => emit(const InvoiceOperationSuccess('Invoice created')),
    );
  }

  Future<void> _onUpdateRecord(
    InvoiceUpdateRecord event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(const InvoiceLoading());
    final result = await _updateInvoice(event.record);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (_) => emit(const InvoiceOperationSuccess('Invoice updated')),
    );
  }

  Future<void> _onDeleteRecord(
    InvoiceDeleteRecord event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(const InvoiceLoading());
    final result = await _deleteInvoice(event.id);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (_) => emit(const InvoiceOperationSuccess('Invoice deleted')),
    );
  }

  Future<void> _onSearchRecords(
    InvoiceSearchRecords event,
    Emitter<InvoiceState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const InvoiceLoadRecords());
      return;
    }

    emit(const InvoiceLoading());
    final result = await _searchInvoices(event.query);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (records) => emit(InvoiceLoaded(
        records: records,
        isSearchResult: true,
        searchQuery: event.query,
      )),
    );
  }

  void _onClearSearch(
    InvoiceClearSearch event,
    Emitter<InvoiceState> emit,
  ) {
    add(const InvoiceLoadRecords());
  }

  @override
  Future<void> close() {
    _recordsSubscription?.cancel();
    return super.close();
  }
}
