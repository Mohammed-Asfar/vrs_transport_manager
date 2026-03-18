import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_config.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_data.dart';

sealed class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object> get props => [];
}

class ReportGenerate extends ReportEvent {
  final ReportConfig config;
  const ReportGenerate(this.config);

  @override
  List<Object> get props => [config];
}

class ReportExportPdf extends ReportEvent {
  final ReportData data;
  const ReportExportPdf(this.data);

  @override
  List<Object> get props => [data];
}

class ReportReset extends ReportEvent {
  const ReportReset();
}
