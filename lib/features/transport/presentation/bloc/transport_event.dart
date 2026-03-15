import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';

sealed class TransportEvent extends Equatable {
  const TransportEvent();

  @override
  List<Object?> get props => [];
}

class TransportLoadRecords extends TransportEvent {
  const TransportLoadRecords();
}

class TransportCreateRecord extends TransportEvent {
  final TransportRecord record;
  const TransportCreateRecord(this.record);

  @override
  List<Object?> get props => [record];
}

class TransportUpdateRecord extends TransportEvent {
  final TransportRecord record;
  const TransportUpdateRecord(this.record);

  @override
  List<Object?> get props => [record];
}

class TransportDeleteRecord extends TransportEvent {
  final String id;
  const TransportDeleteRecord(this.id);

  @override
  List<Object?> get props => [id];
}

class TransportSearchRecords extends TransportEvent {
  final String query;
  const TransportSearchRecords(this.query);

  @override
  List<Object?> get props => [query];
}

class TransportClearSearch extends TransportEvent {
  const TransportClearSearch();
}

class TransportRecordsUpdated extends TransportEvent {
  final List<TransportRecord> records;
  const TransportRecordsUpdated(this.records);

  @override
  List<Object?> get props => [records];
}
