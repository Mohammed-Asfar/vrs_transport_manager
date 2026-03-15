import 'package:equatable/equatable.dart';

class TripEntry extends Equatable {
  final int sNo;
  final String vehicleNo;
  final String transporter;
  final double chainage;
  final double km;
  final double ratePerKm;
  final double amountPerTrip;
  final int noOfLoads;

  const TripEntry({
    required this.sNo,
    required this.vehicleNo,
    required this.transporter,
    required this.chainage,
    required this.km,
    required this.ratePerKm,
    required this.amountPerTrip,
    required this.noOfLoads,
  });

  /// Auto-calculate amount per trip
  factory TripEntry.create({
    required int sNo,
    required String vehicleNo,
    required String transporter,
    required double chainage,
    required double km,
    required double ratePerKm,
    required int noOfLoads,
  }) {
    return TripEntry(
      sNo: sNo,
      vehicleNo: vehicleNo,
      transporter: transporter,
      chainage: chainage,
      km: km,
      ratePerKm: ratePerKm,
      amountPerTrip: km * ratePerKm,
      noOfLoads: noOfLoads,
    );
  }

  TripEntry copyWith({
    int? sNo,
    String? vehicleNo,
    String? transporter,
    double? chainage,
    double? km,
    double? ratePerKm,
    double? amountPerTrip,
    int? noOfLoads,
  }) {
    final newKm = km ?? this.km;
    final newRate = ratePerKm ?? this.ratePerKm;
    return TripEntry(
      sNo: sNo ?? this.sNo,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      transporter: transporter ?? this.transporter,
      chainage: chainage ?? this.chainage,
      km: newKm,
      ratePerKm: newRate,
      amountPerTrip: amountPerTrip ?? (newKm * newRate),
      noOfLoads: noOfLoads ?? this.noOfLoads,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sNo': sNo,
      'vehicleNo': vehicleNo,
      'transporter': transporter,
      'chainage': chainage,
      'km': km,
      'ratePerKm': ratePerKm,
      'amountPerTrip': amountPerTrip,
      'noOfLoads': noOfLoads,
    };
  }

  factory TripEntry.fromMap(Map<String, dynamic> map) {
    return TripEntry(
      sNo: (map['sNo'] as num).toInt(),
      vehicleNo: map['vehicleNo'] as String,
      transporter: map['transporter'] as String,
      chainage: (map['chainage'] as num).toDouble(),
      km: (map['km'] as num).toDouble(),
      ratePerKm: (map['ratePerKm'] as num).toDouble(),
      amountPerTrip: (map['amountPerTrip'] as num).toDouble(),
      noOfLoads: (map['noOfLoads'] as num).toInt(),
    );
  }

  @override
  List<Object> get props => [
        sNo,
        vehicleNo,
        transporter,
        chainage,
        km,
        ratePerKm,
        amountPerTrip,
        noOfLoads,
      ];
}
