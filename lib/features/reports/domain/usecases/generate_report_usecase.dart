import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_config.dart';
import 'package:vrs_transport_manager/features/reports/domain/entities/report_data.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';
import 'package:vrs_transport_manager/features/transport/domain/repositories/transport_repository.dart';

class GenerateReportUseCase {
  final TransportRepository _repository;

  GenerateReportUseCase(this._repository);

  Future<Either<Failure, ReportData>> call(ReportConfig config) async {
    final result = await _repository.getRecordsByDateRange(
      config.startDate,
      config.endDate,
    );

    return result.fold(
      (failure) => Left(failure),
      (records) => Right(_aggregate(records, config)),
    );
  }

  ReportData _aggregate(List<TransportRecord> records, ReportConfig config) {
    // Extract all unique transporter names before filtering
    final availableTransporters = records
        .map((r) => r.transporter)
        .toSet()
        .toList()
      ..sort();

    // Filter by selected transporter if specified
    final filteredRecords = config.selectedTransporter != null
        ? records
            .where((r) => r.transporter == config.selectedTransporter)
            .toList()
        : records;

    // Flatten all trips, tagging each with parent record info
    final allTaggedTrips = <_TaggedTrip>[];

    for (final record in filteredRecords) {
      for (final trip in record.trips) {
        final tripAmount = trip.amountPerTrip * trip.noOfLoads;
        // Proportional diesel/advance allocation
        double dieselShare = 0;
        double advanceShare = 0;
        if (record.totalAmount > 0) {
          final proportion = tripAmount / record.totalAmount;
          dieselShare = record.diesel * proportion;
          advanceShare = record.advance * proportion;
        } else if (record.trips.isNotEmpty) {
          // Distribute equally if totalAmount is 0
          dieselShare = record.diesel / record.trips.length;
          advanceShare = record.advance / record.trips.length;
        }

        allTaggedTrips.add(_TaggedTrip(
          reportTrip: ReportTrip(
            date: record.date,
            location: record.location,
            vehicleNo: trip.vehicleNo,
            transporter: record.transporter,
            chainage: trip.chainage,
            km: trip.km,
            ratePerKm: trip.ratePerKm,
            amountPerTrip: trip.amountPerTrip,
            noOfLoads: trip.noOfLoads,
          ),
          dieselShare: dieselShare,
          advanceShare: advanceShare,
        ));
      }
    }

    // Group by transporter
    final groupMap = <String, List<_TaggedTrip>>{};
    for (final tagged in allTaggedTrips) {
      final key = tagged.reportTrip.transporter;
      groupMap.putIfAbsent(key, () => []).add(tagged);
    }

    // Build groups
    final groups = groupMap.entries.map((entry) {
      final trips = entry.value;
      final totalLoads =
          trips.fold<int>(0, (sum, t) => sum + t.reportTrip.noOfLoads);
      final totalAmount = trips.fold<double>(
          0, (sum, t) => sum + t.reportTrip.amountPerTrip * t.reportTrip.noOfLoads);
      final dieselShare =
          trips.fold<double>(0, (sum, t) => sum + t.dieselShare);
      final advanceShare =
          trips.fold<double>(0, (sum, t) => sum + t.advanceShare);

      return ReportGroup(
        groupKey: entry.key,
        trips: trips.map((t) => t.reportTrip).toList(),
        totalLoads: totalLoads,
        totalAmount: totalAmount,
        dieselShare: dieselShare,
        advanceShare: advanceShare,
        balance: totalAmount - dieselShare - advanceShare,
      );
    }).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    // Compute unique sets
    final uniqueTransporters = <String>{};
    final uniqueVehicles = <String>{};
    for (final t in allTaggedTrips) {
      uniqueTransporters.add(t.reportTrip.transporter);
      uniqueVehicles.add(t.reportTrip.vehicleNo);
    }

    final overview = ReportOverview(
      totalRecords: filteredRecords.length,
      totalTrips: allTaggedTrips.length,
      totalLoads: filteredRecords.fold<int>(0, (sum, r) => sum + r.totalLoads),
      totalAmount: filteredRecords.fold<double>(0, (sum, r) => sum + r.totalAmount),
      totalDiesel: filteredRecords.fold<double>(0, (sum, r) => sum + r.diesel),
      totalAdvance: filteredRecords.fold<double>(0, (sum, r) => sum + r.advance),
      totalBalance: filteredRecords.fold<double>(0, (sum, r) => sum + r.balance),
      uniqueTransporters: uniqueTransporters.length,
      uniqueVehicles: uniqueVehicles.length,
    );

    return ReportData(
      config: config,
      overview: overview,
      groups: groups,
      availableTransporters: availableTransporters,
    );
  }
}

class _TaggedTrip {
  final ReportTrip reportTrip;
  final double dieselShare;
  final double advanceShare;

  const _TaggedTrip({
    required this.reportTrip,
    required this.dieselShare,
    required this.advanceShare,
  });
}
