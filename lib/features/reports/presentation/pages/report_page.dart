import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_config.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_data.dart';
import 'package:vrs_transport_manager/features/reports/presentation/bloc/report_bloc.dart';
import 'package:vrs_transport_manager/features/reports/presentation/bloc/report_event.dart';
import 'package:vrs_transport_manager/features/reports/presentation/bloc/report_state.dart';
import 'package:vrs_transport_manager/features/reports/presentation/widgets/date_range_selector.dart';
import 'package:vrs_transport_manager/features/reports/presentation/widgets/report_empty_state.dart';
import 'package:vrs_transport_manager/features/reports/presentation/widgets/report_group_table.dart';
import 'package:vrs_transport_manager/features/reports/presentation/widgets/report_overview_cards.dart';
import 'package:vrs_transport_manager/features/reports/presentation/widgets/transporter_filter.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late ReportConfig _config;
  List<String> _availableTransporters = [];

  @override
  void initState() {
    super.initState();
    _config = context.read<ReportBloc>().state.config;
    // Auto-generate report on page load to populate transporter dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generate();
    });
  }

  void _updateConfig(ReportConfig config) {
    setState(() => _config = config);
  }

  void _generate() {
    context.read<ReportBloc>().add(ReportGenerate(_config));
  }

  void _export(ReportData data, ExportTarget target) {
    context.read<ReportBloc>().add(ReportExportPdf(data, exportTarget: target));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.toolbar,
        border: Border(
          bottom: BorderSide(color: AppColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.summarize_outlined,
              size: 20, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Reports', style: AppTextStyles.heading3),
          const Spacer(),
          BlocBuilder<ReportBloc, ReportState>(
            builder: (context, state) {
              if (state is! ReportLoaded && state is! ReportExporting) {
                return const SizedBox.shrink();
              }

              final data = switch (state) {
                ReportLoaded s => s.data,
                ReportExporting s => s.data,
                _ => null,
              };
              if (data == null) return const SizedBox.shrink();
              final isExporting = state is ReportExporting;

              return SizedBox(
                height: 32,
                child: PopupMenuButton<ExportTarget>(
                  enabled: !isExporting,
                  onSelected: (target) => _export(data, target),
                  offset: const Offset(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(
                        color: AppColors.separator, width: 0.5),
                  ),
                  color: AppColors.surface,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: ExportTarget.company,
                      height: 36,
                      child: Row(
                        children: [
                          Icon(Icons.business_rounded,
                              size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('Company Export'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: ExportTarget.transporter,
                      height: 36,
                      child: Row(
                        children: [
                          Icon(Icons.local_shipping_rounded,
                              size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('Transporter Export'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isExporting
                          ? AppColors.accent.withValues(alpha: 0.5)
                          : AppColors.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isExporting)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(Icons.picture_as_pdf_rounded,
                              size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          isExporting ? 'Exporting...' : 'Export PDF',
                          style: AppTextStyles.button
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down,
                            size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.separator, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DateRangeSelector(
                      config: _config,
                      onChanged: _updateConfig,
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<ReportBloc, ReportState>(
                      builder: (context, state) {
                        if (state is ReportLoaded) {
                          _availableTransporters =
                              state.data.availableTransporters;
                        } else if (state is ReportExporting) {
                          _availableTransporters =
                              state.data.availableTransporters;
                        }
                        // Clear stale transporter selection
                        if (_config.selectedTransporter != null &&
                            !_availableTransporters
                                .contains(_config.selectedTransporter)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _updateConfig(_config.copyWith(
                                clearSelectedTransporter: true));
                          });
                        }
                        return TransporterFilter(
                          selectedTransporter: _config.selectedTransporter,
                          availableTransporters: _availableTransporters,
                          onChanged: (value) {
                            if (value == null) {
                              _updateConfig(_config.copyWith(
                                  clearSelectedTransporter: true));
                            } else {
                              _updateConfig(_config.copyWith(
                                  selectedTransporter: value));
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: BlocBuilder<ReportBloc, ReportState>(
                builder: (context, state) {
                  final isLoading = state is ReportLoading;
                  return ElevatedButton.icon(
                    onPressed: isLoading ? null : _generate,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : const Icon(Icons.insights_rounded, size: 18),
                    label: Text(
                        isLoading ? 'Generating...' : 'Generate Report'),
                    style: ElevatedButton.styleFrom(
                      textStyle: AppTextStyles.button,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocConsumer<ReportBloc, ReportState>(
      listener: (context, state) {
        if (state is ReportError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
        if (state is ReportExported) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF exported successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildContentForState(state),
        );
      },
    );
  }

  Widget _buildContentForState(ReportState state) {
    if (state is ReportInitial) {
      return const ReportEmptyState(key: ValueKey('initial'));
    }

    if (state is ReportLoading) {
      return const _LoadingSkeleton(key: ValueKey('loading'));
    }

    if (state is ReportError) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 36, color: AppColors.error.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(state.message,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 28,
              child: OutlinedButton(
                onPressed: _generate,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    // ReportLoaded or ReportExporting
    final data = state is ReportLoaded
        ? state.data
        : (state as ReportExporting).data;

    if (data.groups.isEmpty) {
      return const ReportEmptyState(
          key: ValueKey('empty'), isNoResults: true);
    }

    return Padding(
      key: const ValueKey('loaded'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ReportOverviewCards(overview: data.overview),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.separator, width: 0.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ReportGroupTable(data: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Skeleton stat cards
          Row(
            children: List.generate(
              5,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 4 ? 10 : 0),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.separator, width: 0.5),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Skeleton table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.separator, width: 0.5),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.accent,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('Generating report...',
                        style: TextStyle(color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
