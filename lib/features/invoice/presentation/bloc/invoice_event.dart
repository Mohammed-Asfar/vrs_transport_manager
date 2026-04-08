import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';

sealed class InvoiceEvent extends Equatable {
  const InvoiceEvent();

  @override
  List<Object?> get props => [];
}

class InvoiceLoadRecords extends InvoiceEvent {
  const InvoiceLoadRecords();
}

class InvoiceRecordsUpdated extends InvoiceEvent {
  final List<InvoiceRecord> records;
  const InvoiceRecordsUpdated(this.records);

  @override
  List<Object?> get props => [records];
}

class InvoiceCreateRecord extends InvoiceEvent {
  final InvoiceRecord record;
  const InvoiceCreateRecord(this.record);

  @override
  List<Object?> get props => [record];
}

class InvoiceUpdateRecord extends InvoiceEvent {
  final InvoiceRecord record;
  const InvoiceUpdateRecord(this.record);

  @override
  List<Object?> get props => [record];
}

class InvoiceDeleteRecord extends InvoiceEvent {
  final String id;
  const InvoiceDeleteRecord(this.id);

  @override
  List<Object?> get props => [id];
}

class InvoiceSearchRecords extends InvoiceEvent {
  final String query;
  const InvoiceSearchRecords(this.query);

  @override
  List<Object?> get props => [query];
}

class InvoiceClearSearch extends InvoiceEvent {
  const InvoiceClearSearch();
}
