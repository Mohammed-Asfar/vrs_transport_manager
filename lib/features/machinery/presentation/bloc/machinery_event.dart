import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/machinery_record.dart';

sealed class MachineryEvent extends Equatable {
  const MachineryEvent();

  @override
  List<Object?> get props => [];
}

class MachineryLoadRecords extends MachineryEvent {
  const MachineryLoadRecords();
}

class MachineryCreateRecord extends MachineryEvent {
  final MachineryRecord record;
  const MachineryCreateRecord(this.record);

  @override
  List<Object?> get props => [record];
}

class MachineryUpdateRecord extends MachineryEvent {
  final MachineryRecord record;
  const MachineryUpdateRecord(this.record);

  @override
  List<Object?> get props => [record];
}

class MachineryDeleteRecord extends MachineryEvent {
  final String id;
  const MachineryDeleteRecord(this.id);

  @override
  List<Object?> get props => [id];
}

class MachinerySearchRecords extends MachineryEvent {
  final String query;
  const MachinerySearchRecords(this.query);

  @override
  List<Object?> get props => [query];
}

class MachineryClearSearch extends MachineryEvent {
  const MachineryClearSearch();
}

class MachineryRecordsUpdated extends MachineryEvent {
  final List<MachineryRecord> records;
  const MachineryRecordsUpdated(this.records);

  @override
  List<Object?> get props => [records];
}
