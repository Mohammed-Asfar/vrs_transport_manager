import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/utils/date_formatter.dart';
import 'package:vrs_transport_manager/core/widgets/confirmation_dialog.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';
import 'package:vrs_transport_manager/features/transport/presentation/bloc/transport_bloc.dart';
import 'package:vrs_transport_manager/features/transport/presentation/bloc/transport_event.dart';
import 'package:vrs_transport_manager/features/transport/presentation/bloc/transport_state.dart';
import 'package:vrs_transport_manager/core/services/update_checker_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TransportBloc>().add(const TransportLoadRecords());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateCheckerService().checkForUpdates(context);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// macOS Finder-style toolbar.
  Widget _buildToolbar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.toolbar,
        border: Border(
          bottom: BorderSide(color: AppColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_outlined,
              size: 20, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Transport', style: AppTextStyles.heading3),
          const Spacer(),

          // Search
          SizedBox(
            width: 280,
            height: 36,
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 8, right: 4),
                  child: Icon(Icons.search,
                      size: 16, color: AppColors.textTertiary),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 32, minHeight: 36),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          context
                              .read<TransportBloc>()
                              .add(const TransportClearSearch());
                          setState(() {});
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.close,
                              size: 14, color: AppColors.textTertiary),
                        ),
                      )
                    : null,
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 24, minHeight: 24),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.trim().isEmpty) {
                  context
                      .read<TransportBloc>()
                      .add(const TransportClearSearch());
                } else {
                  context
                      .read<TransportBloc>()
                      .add(TransportSearchRecords(value));
                }
              },
            ),
          ),
          const SizedBox(width: 12),

          // New Record
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/create'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Record'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocConsumer<TransportBloc, TransportState>(
      listener: (context, state) {
        if (state is TransportError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error),
          );
        }
        if (state is TransportOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success),
          );
        }
      },
      builder: (context, state) {
        if (state is TransportLoading) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.accent),
            ),
          );
        }

        if (state is TransportLoaded) {
          if (state.records.isEmpty) {
            return _buildEmptyState(state.isSearchResult);
          }
          return _buildFinderList(
              state.records, state.isSearchResult, state.searchQuery);
        }

        if (state is TransportError) {
          return Center(
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
                    onPressed: () => context
                        .read<TransportBloc>()
                        .add(const TransportLoadRecords()),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState(bool isSearch) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearch ? Icons.search_off_rounded : Icons.inbox_rounded,
            size: 44,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            isSearch ? 'No records found' : 'No transport records yet',
            style:
                AppTextStyles.heading3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? 'Try a different search term'
                : 'Click "+ New Record" to create your first entry',
            style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  /// Finder-style list with column header bar and alternating-free rows.
  Widget _buildFinderList(
      List<TransportRecord> records, bool isSearch, String query) {
    return Column(
      children: [
        // Column header
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: AppColors.surfaceSecondary,
            border: Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                  width: 70,
                  child: Text('Date', style: AppTextStyles.tableHeader)),
              const SizedBox(width: 16),
              Expanded(
                  flex: 3,
                  child: Text('Location', style: AppTextStyles.tableHeader)),
              Expanded(
                  flex: 2,
                  child: Text('Details', style: AppTextStyles.tableHeader)),
              SizedBox(
                width: 100,
                child: Text('Balance',
                    style: AppTextStyles.tableHeader,
                    textAlign: TextAlign.right),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),

        // Status bar
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: AppColors.toolbar,
            border: Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Text(
                isSearch ? 'Search Results' : 'All Records',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${records.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Rows
        Expanded(
          child: Container(
            color: AppColors.surface,
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return _FinderRow(
                  record: record,
                  isLast: index == records.length - 1,
                  onTap: () => context.push('/detail/${record.id}'),
                  onEdit: () => context.push('/edit/${record.id}'),
                  onDelete: () => _deleteRecord(record),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteRecord(TransportRecord record) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Record',
      message:
          'Delete the record for ${record.location} on ${DateFormatter.toDisplay(record.date)}?',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
      icon: Icons.delete_outline_rounded,
    );
    if (confirm == true && mounted) {
      context.read<TransportBloc>().add(TransportDeleteRecord(record.id!));
    }
  }
}

/// Finder-style row with hover highlight.
class _FinderRow extends StatefulWidget {
  final TransportRecord record;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FinderRow({
    required this.record,
    required this.isLast,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_FinderRow> createState() => _FinderRowState();
}

class _FinderRowState extends State<_FinderRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.accentLight : AppColors.surface,
            border: widget.isLast
                ? null
                : const Border(
                    bottom: BorderSide(
                        color: AppColors.separatorLight, width: 0.5),
                  ),
          ),
          child: Row(
            children: [
              // Date
              SizedBox(
                width: 70,
                child: Text(
                  '${widget.record.date.day.toString().padLeft(2, '0')} ${_monthName(widget.record.date.month)}',
                  style: AppTextStyles.subtitle
                      .copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 16),

              // Location
              Expanded(
                flex: 3,
                child: Text(
                  widget.record.location,
                  style:
                      AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Details
              Expanded(
                flex: 2,
                child: Text(
                  '${widget.record.transporter} · ${widget.record.totalLoads} loads',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Balance
              SizedBox(
                width: 100,
                child: Text(
                  '₹${widget.record.balance.toStringAsFixed(0)}',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.record.balance >= 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),

              // Context menu
              SizedBox(
                width: 36,
                height: 36,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  icon: Icon(
                    Icons.more_horiz,
                    color: _hovered
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                    size: 20,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        widget.onTap();
                      case 'edit':
                        widget.onEdit();
                      case 'delete':
                        widget.onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    _menuItem(
                        'view', Icons.visibility_outlined, 'View Details'),
                    _menuItem('edit', Icons.edit_outlined, 'Edit'),
                    _menuItem('delete', Icons.delete_outline, 'Delete',
                        color: AppColors.error),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label,
      {Color? color}) {
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: AppTextStyles.body
                  .copyWith(color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }
}
