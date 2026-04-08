import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';

sealed class InvoiceState extends Equatable {
  const InvoiceState();

  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {
  const InvoiceInitial();
}

class InvoiceLoading extends InvoiceState {
  const InvoiceLoading();
}

class InvoiceLoaded extends InvoiceState {
  final List<InvoiceRecord> records;
  final bool isSearchResult;
  final String searchQuery;

  const InvoiceLoaded({
    required this.records,
    this.isSearchResult = false,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [records, isSearchResult, searchQuery];
}

class InvoiceOperationSuccess extends InvoiceState {
  final String message;
  const InvoiceOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class InvoiceError extends InvoiceState {
  final String message;
  const InvoiceError(this.message);

  @override
  List<Object?> get props => [message];
}
