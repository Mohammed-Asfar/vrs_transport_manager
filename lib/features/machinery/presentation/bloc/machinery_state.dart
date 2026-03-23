import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/machinery_record.dart';

sealed class MachineryState extends Equatable {
  const MachineryState();

  @override
  List<Object?> get props => [];
}

class MachineryInitial extends MachineryState {
  const MachineryInitial();
}

class MachineryLoading extends MachineryState {
  const MachineryLoading();
}

class MachineryLoaded extends MachineryState {
  final List<MachineryRecord> records;
  final bool isSearchResult;
  final String searchQuery;

  const MachineryLoaded({
    required this.records,
    this.isSearchResult = false,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [records, isSearchResult, searchQuery];
}

class MachineryOperationSuccess extends MachineryState {
  final String message;

  const MachineryOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MachineryError extends MachineryState {
  final String message;

  const MachineryError(this.message);

  @override
  List<Object?> get props => [message];
}
