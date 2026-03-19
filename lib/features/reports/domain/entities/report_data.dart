import 'package:equatable/equatable.dart';
import 'report_config.dart';

class ReportData extends Equatable {
  final ReportConfig config;
  final ReportOverview overview;
  final List<ReportGroup> groups;
  final List<String> availableTransporters;

  const ReportData({
    required this.config,
    required this.overview,
    required this.groups,
    required this.availableTransporters,
  });

  @override
  List<Object> get props => [config, overview, groups, availableTransporters];
}

class ReportOverview extends Equatable {
  final int totalRecords;
  final int totalTrips;
  final int totalLoads;
  final double totalAmount;
  final double totalDiesel;
  final double totalAdvance;
  final double totalBalance;
  final int uniqueTransporters;
  final int uniqueVehicles;

  const ReportOverview({
    required this.totalRecords,
    required this.totalTrips,
    required this.totalLoads,
    required this.totalAmount,
    required this.totalDiesel,
    required this.totalAdvance,
    required this.totalBalance,
    required this.uniqueTransporters,
    required this.uniqueVehicles,
  });

  @override
  List<Object> get props => [
        totalRecords,
        totalTrips,
        totalLoads,
        totalAmount,
        totalDiesel,
        totalAdvance,
        totalBalance,
        uniqueTransporters,
        uniqueVehicles,
      ];
}

class ReportGroup extends Equatable {
  final String groupKey;
  final List<ReportTrip> trips;
  final int totalLoads;
  final double totalAmount;
  final double dieselShare;
  final double advanceShare;
  final double balance;

  const ReportGroup({
    required this.groupKey,
    required this.trips,
    required this.totalLoads,
    required this.totalAmount,
    required this.dieselShare,
    required this.advanceShare,
    required this.balance,
  });

  @override
  List<Object> get props =>
      [groupKey, trips, totalLoads, totalAmount, dieselShare, advanceShare, balance];
}

class ReportTrip extends Equatable {
  final DateTime date;
  final String location;
  final String vehicleNo;
  final String transporter;
  final double chainage;
  final double km;
  final double ratePerKm;
  final double amountPerTrip;
  final int noOfLoads;

  const ReportTrip({
    required this.date,
    required this.location,
    required this.vehicleNo,
    required this.transporter,
    required this.chainage,
    required this.km,
    required this.ratePerKm,
    required this.amountPerTrip,
    required this.noOfLoads,
  });

  @override
  List<Object> get props => [
        date,
        location,
        vehicleNo,
        transporter,
        chainage,
        km,
        ratePerKm,
        amountPerTrip,
        noOfLoads,
      ];
}
