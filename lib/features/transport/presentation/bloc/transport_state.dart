import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';

sealed class TransportState extends Equatable {
  const TransportState();

  @override
  List<Object?> get props => [];
}

class TransportInitial extends TransportState {
  const TransportInitial();
}

class TransportLoading extends TransportState {
  const TransportLoading();
}

class TransportLoaded extends TransportState {
  final List<TransportRecord> records;
  final bool isSearchResult;
  final String searchQuery;

  const TransportLoaded({
    required this.records,
    this.isSearchResult = false,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [records, isSearchResult, searchQuery];
}

class TransportOperationSuccess extends TransportState {
  final String message;

  const TransportOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TransportError extends TransportState {
  final String message;

  const TransportError(this.message);

  @override
  List<Object?> get props => [message];
}
