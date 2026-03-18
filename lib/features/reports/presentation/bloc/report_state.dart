import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_config.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_data.dart';

sealed class ReportState extends Equatable {
  final ReportConfig config;
  const ReportState(this.config);

  @override
  List<Object> get props => [config];
}

class ReportInitial extends ReportState {
  const ReportInitial(super.config);
}

class ReportLoading extends ReportState {
  const ReportLoading(super.config);
}

class ReportLoaded extends ReportState {
  final ReportData data;
  const ReportLoaded({required ReportConfig config, required this.data})
      : super(config);

  @override
  List<Object> get props => [config, data];
}

class ReportExporting extends ReportState {
  final ReportData data;
  const ReportExporting({required ReportConfig config, required this.data})
      : super(config);

  @override
  List<Object> get props => [config, data];
}

class ReportExported extends ReportState {
  final ReportData data;
  const ReportExported({required ReportConfig config, required this.data})
      : super(config);

  @override
  List<Object> get props => [config, data];
}

class ReportError extends ReportState {
  final String message;
  const ReportError({required ReportConfig config, required this.message})
      : super(config);

  @override
  List<Object> get props => [config, message];
}
