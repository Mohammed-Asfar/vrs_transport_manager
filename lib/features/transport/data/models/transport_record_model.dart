import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/trip_entry.dart';

class TransportRecordModel extends TransportRecord {
  const TransportRecordModel({
    super.id,
    required super.date,
    required super.location,
    required super.transporter,
    required super.trips,
    required super.totalLoads,
    required super.totalAmount,
    required super.diesel,
    required super.advance,
    required super.balance,
    super.createdAt,
    super.updatedAt,
    super.createdBy,
  });

  factory TransportRecordModel.fromEntity(TransportRecord entity) {
    return TransportRecordModel(
      id: entity.id,
      date: entity.date,
      location: entity.location,
      transporter: entity.transporter,
      trips: entity.trips,
      totalLoads: entity.totalLoads,
      totalAmount: entity.totalAmount,
      diesel: entity.diesel,
      advance: entity.advance,
      balance: entity.balance,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
    );
  }

  factory TransportRecordModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    final trips = (data['trips'] as List<dynamic>?)
            ?.map((t) => TripEntry.fromMap(t as Map<String, dynamic>))
            .toList() ??
        [];

    // Migration: read transporter from record level, fallback to first trip's
    // transporter field (old schema stored it per-trip)
    String transporter = data['transporter'] as String? ?? '';
    if (transporter.isEmpty && trips.isNotEmpty) {
      final firstTripData = (data['trips'] as List<dynamic>?)?.first
          as Map<String, dynamic>?;
      transporter = firstTripData?['transporter'] as String? ?? '';
    }

    return TransportRecordModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] as String? ?? '',
      transporter: transporter,
      trips: trips,
      totalLoads: (data['totalLoads'] as num?)?.toInt() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      diesel: (data['diesel'] as num?)?.toDouble() ?? 0,
      advance: (data['advance'] as num?)?.toDouble() ?? 0,
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'location': location,
      'transporter': transporter,
      'trips': trips.map((t) => t.toMap()).toList(),
      'totalLoads': totalLoads,
      'totalAmount': totalAmount,
      'diesel': diesel,
      'advance': advance,
      'balance': balance,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
