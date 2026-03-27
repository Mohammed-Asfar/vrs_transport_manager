import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vrs_transport_manager/core/utils/report_pdf_generator.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_config.dart';
import 'package:vrs_transport_manager/features/reports/domain/usecases/generate_report_usecase.dart';
export 'package:vrs_transport_manager/features/reports/domain/entities/report_config.dart' show ExportTarget;
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final GenerateReportUseCase _generateReport;

  ReportBloc({required GenerateReportUseCase generateReport})
      : _generateReport = generateReport,
        super(ReportInitial(ReportConfig.thisWeek())) {
    on<ReportGenerate>(_onGenerate);
    on<ReportExportPdf>(_onExportPdf);
    on<ReportReset>(_onReset);
  }

  Future<void> _onGenerate(
    ReportGenerate event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading(event.config));

    final result = await _generateReport(event.config);

    result.fold(
      (failure) =>
          emit(ReportError(config: event.config, message: failure.message)),
      (data) => emit(ReportLoaded(config: event.config, data: data)),
    );
  }

  Future<void> _onExportPdf(
    ReportExportPdf event,
    Emitter<ReportState> emit,
  ) async {
    final config = state.config;
    emit(ReportExporting(config: config, data: event.data));

    try {
      await ReportPdfGenerator.generateAndPrint(event.data,
          exportTarget: event.exportTarget);
      emit(ReportLoaded(config: config, data: event.data));
    } catch (e) {
      emit(ReportError(config: config, message: 'Failed to generate PDF: $e'));
    }
  }

  void _onReset(ReportReset event, Emitter<ReportState> emit) {
    emit(ReportInitial(ReportConfig.thisWeek()));
  }
}
