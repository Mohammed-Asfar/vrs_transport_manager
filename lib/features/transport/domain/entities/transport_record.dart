import 'package:equatable/equatable.dart';
import 'trip_entry.dart';

class TransportRecord extends Equatable {
  final String? id;
  final DateTime date;
  final String location;
  final String transporter;
  final List<TripEntry> trips;
  final int totalLoads;
  final double totalAmount;
  final double diesel;
  final double advance;
  final double balance;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  const TransportRecord({
    this.id,
    required this.date,
    required this.location,
    required this.transporter,
    required this.trips,
    required this.totalLoads,
    required this.totalAmount,
    required this.diesel,
    required this.advance,
    required this.balance,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// Auto-calculate totals from trips
  factory TransportRecord.create({
    String? id,
    required DateTime date,
    required String location,
    required String transporter,
    required List<TripEntry> trips,
    required double diesel,
    required double advance,
    String? createdBy,
  }) {
    final totalLoads = trips.fold<int>(0, (sum, t) => sum + t.noOfLoads);
    final totalAmount = trips.fold<double>(
      0,
      (sum, t) => sum + (t.amountPerTrip * t.noOfLoads),
    );
    final balance = totalAmount - diesel - advance;

    return TransportRecord(
      id: id,
      date: date,
      location: location,
      transporter: transporter,
      trips: trips,
      totalLoads: totalLoads,
      totalAmount: totalAmount,
      diesel: diesel,
      advance: advance,
      balance: balance,
      createdBy: createdBy,
    );
  }

  TransportRecord copyWith({
    String? id,
    DateTime? date,
    String? location,
    String? transporter,
    List<TripEntry>? trips,
    int? totalLoads,
    double? totalAmount,
    double? diesel,
    double? advance,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return TransportRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      location: location ?? this.location,
      transporter: transporter ?? this.transporter,
      trips: trips ?? this.trips,
      totalLoads: totalLoads ?? this.totalLoads,
      totalAmount: totalAmount ?? this.totalAmount,
      diesel: diesel ?? this.diesel,
      advance: advance ?? this.advance,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        location,
        transporter,
        trips,
        totalLoads,
        totalAmount,
        diesel,
        advance,
        balance,
        createdAt,
        updatedAt,
        createdBy,
      ];
}
