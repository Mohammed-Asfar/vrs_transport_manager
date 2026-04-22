import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/payment/domain/entities/payment.dart';
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
  final ExportTarget exportTarget;

  /// Map of normalized transporter name → list of payments
  final Map<String, List<Payment>> paymentsByTransporter;

  const ReportExportPdf(
    this.data, {
    this.exportTarget = ExportTarget.transporter,
    this.paymentsByTransporter = const {},
  });

  @override
  List<Object> get props => [data, exportTarget, paymentsByTransporter];
}

class ReportReset extends ReportEvent {
  const ReportReset();
}
