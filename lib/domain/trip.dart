import 'package:cloud_firestore/cloud_firestore.dart';

enum TripStatus { presupuesto, activo, completado }

class Trip {
  final String id;

  final String destinationId;
  final String destinationName;
  final String destinationImageUrl;
  final bool isTouristic;

  final TripStatus state;

  final int durationDays;
  final DateTime? tripDate;
  final bool cheapestMonth;
  final int people;
  final int hotelStars;
  final int maxDistanceKm;
  final String transport;

  final double transportCostUsd;
  final double hotelCostUsd;
  final double totalUsd;
  final double totalArsCache;
  final double mepRateUsed;
  final DateTime pricesUpdatedAt;

  final DateTime savingsTargetDate;

  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? archivedAt;

  const Trip({
    required this.id,
    required this.destinationId,
    required this.destinationName,
    required this.destinationImageUrl,
    required this.isTouristic,
    required this.state,
    required this.durationDays,
    required this.tripDate,
    required this.cheapestMonth,
    required this.people,
    required this.hotelStars,
    required this.maxDistanceKm,
    required this.transport,
    required this.transportCostUsd,
    required this.hotelCostUsd,
    required this.totalUsd,
    required this.totalArsCache,
    required this.mepRateUsed,
    required this.pricesUpdatedAt,
    required this.savingsTargetDate,
    required this.createdAt,
    required this.confirmedAt,
    required this.archivedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'destinationId': destinationId,
      'destinationName': destinationName,
      'destinationImageUrl': destinationImageUrl,
      'isTouristic': isTouristic,
      'state': state.name,
      'durationDays': durationDays,
      'tripDate': tripDate == null ? null : Timestamp.fromDate(tripDate!),
      'cheapestMonth': cheapestMonth,
      'people': people,
      'hotelStars': hotelStars,
      'maxDistanceKm': maxDistanceKm,
      'transport': transport,
      'transportCostUsd': transportCostUsd,
      'hotelCostUsd': hotelCostUsd,
      'totalUsd': totalUsd,
      'totalArsCache': totalArsCache,
      'mepRateUsed': mepRateUsed,
      'pricesUpdatedAt': Timestamp.fromDate(pricesUpdatedAt),
      'savingsTargetDate': Timestamp.fromDate(savingsTargetDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt':
          confirmedAt == null ? null : Timestamp.fromDate(confirmedAt!),
      'archivedAt':
          archivedAt == null ? null : Timestamp.fromDate(archivedAt!),
    };
  }

  static Trip fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? {};

    return Trip(
      id: snapshot.id,
      destinationId: data['destinationId'] ?? '',
      destinationName: data['destinationName'] ?? '',
      destinationImageUrl: data['destinationImageUrl'] ?? '',
      isTouristic: data['isTouristic'] ?? false,
      state: TripStatus.values.firstWhere(
        (e) => e.name == data['state'],
        orElse: () => TripStatus.presupuesto,
      ),
      durationDays: data['durationDays'] ?? 0,
      tripDate: (data['tripDate'] as Timestamp?)?.toDate(),
      cheapestMonth: data['cheapestMonth'] ?? false,
      people: data['people'] ?? 0,
      hotelStars: data['hotelStars'] ?? 0,
      maxDistanceKm: data['maxDistanceKm'] ?? 0,
      transport: data['transport'] ?? '',
      transportCostUsd:
          (data['transportCostUsd'] as num?)?.toDouble() ?? 0.0,
      hotelCostUsd: (data['hotelCostUsd'] as num?)?.toDouble() ?? 0.0,
      totalUsd: (data['totalUsd'] as num?)?.toDouble() ?? 0.0,
      totalArsCache:
          (data['totalArsCache'] as num?)?.toDouble() ?? 0.0,
      mepRateUsed:
          (data['mepRateUsed'] as num?)?.toDouble() ?? 0.0,
      pricesUpdatedAt:
          (data['pricesUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      savingsTargetDate:
          (data['savingsTargetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedAt:
          (data['confirmedAt'] as Timestamp?)?.toDate(),
      archivedAt:
          (data['archivedAt'] as Timestamp?)?.toDate(),
    );
  }

  Trip copyWith({
    TripStatus? state,
    int? people,
    double? transportCostUsd,
    double? hotelCostUsd,
    double? totalUsd,
    double? totalArsCache,
    double? mepRateUsed,
    DateTime? pricesUpdatedAt,
    DateTime? confirmedAt,
    DateTime? archivedAt,
  }) {
    return Trip(
      id: id,
      destinationId: destinationId,
      destinationName: destinationName,
      destinationImageUrl: destinationImageUrl,
      isTouristic: isTouristic,
      state: state ?? this.state,
      durationDays: durationDays,
      tripDate: tripDate,
      cheapestMonth: cheapestMonth,
      people: people ?? this.people,
      hotelStars: hotelStars,
      maxDistanceKm: maxDistanceKm,
      transport: transport,
      transportCostUsd: transportCostUsd ?? this.transportCostUsd,
      hotelCostUsd: hotelCostUsd ?? this.hotelCostUsd,
      totalUsd: totalUsd ?? this.totalUsd,
      totalArsCache: totalArsCache ?? this.totalArsCache,
      mepRateUsed: mepRateUsed ?? this.mepRateUsed,
      pricesUpdatedAt: pricesUpdatedAt ?? this.pricesUpdatedAt,
      savingsTargetDate: savingsTargetDate,
      createdAt: createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}

