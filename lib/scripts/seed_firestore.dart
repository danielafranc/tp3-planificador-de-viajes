import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/trip.dart';

class SeedResult {
  final bool ok;
  final String message;
  final int writtenCount;

  const SeedResult({
    required this.ok,
    required this.message,
    this.writtenCount = 0,
  });
}

Future<SeedResult> seedTripsForCurrentUser() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    return const SeedResult(
      ok: false,
      message: 'Tenés que estar logueada para cargar viajes.',
    );
  }

  final firestore = FirebaseFirestore.instance;

  try {
    final destSnapshot = await firestore
        .collection('destinations')
        .limit(5)
        .get();

    if (destSnapshot.docs.isEmpty) {
      return const SeedResult(
        ok: false,
        message: 'No hay destinos en /destinations. Cargá el catálogo primero.',
      );
    }

    final destinations = destSnapshot.docs;
    final now = DateTime.now();
    final tripsCol = firestore
        .collection('users')
        .doc(uid)
        .collection('trips');

    final entries = _tripConfigurations(destinations.length);

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final destDoc = destinations[i % destinations.length];
      final destData = destDoc.data();

      final isTouristic = (destData['isTouristic'] as bool?) ?? true;
      final tripDate = DateTime(
        now.year,
        now.month + (entry['monthsAhead'] as int),
        15,
      );
      final monthsBack = isTouristic ? 3 : 1;
      final savingsTargetDate = DateTime(
        tripDate.year,
        tripDate.month - monthsBack,
        tripDate.day,
      );

      final transportCost = entry['transportCostUsd'] as double;
      final hotelCost = entry['hotelCostUsd'] as double;
      final total = transportCost + hotelCost;
      final state = entry['state'] as TripStatus;

      await tripsCol.doc().set({
        'destinationId': destDoc.id,
        'destinationName': destData['name'] ?? '?',
        'destinationImageUrl': destData['imageUrl'] ?? '',
        'isTouristic': isTouristic,
        'state': state.name,
        'durationDays': entry['days'],
        'tripDate': Timestamp.fromDate(tripDate),
        'cheapestMonth': false,
        'people': entry['people'],
        'hotelStars': entry['hotelStars'],
        'maxDistanceKm': entry['maxDistanceKm'],
        'transport': entry['transport'],
        'transportCostUsd': transportCost,
        'hotelCostUsd': hotelCost,
        'totalUsd': total,
        'totalArsCache': total * 1100.0,
        'mepRateUsed': 1100.0,
        'pricesUpdatedAt': Timestamp.fromDate(now),
        'savingsTargetDate': Timestamp.fromDate(savingsTargetDate),
        'createdAt': Timestamp.fromDate(now),
        'confirmedAt': state == TripStatus.activo
            ? Timestamp.fromDate(now)
            : null,
        'archivedAt': state == TripStatus.completado
            ? Timestamp.fromDate(now)
            : null,
      });
    }

    return SeedResult(
      ok: true,
      message: 'Se cargaron ${entries.length} viajes en tu usuario.',
      writtenCount: entries.length,
    );
  } catch (e) {
    return SeedResult(
      ok: false,
      message: 'Error al cargar viajes: $e',
    );
  }
}

Future<SeedResult> seedSavingsForCurrentUser() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    return const SeedResult(
      ok: false,
      message: 'Tenés que estar logueada para cargar ahorros.',
    );
  }

  final firestore = FirebaseFirestore.instance;

  try {
    final movementsCol = firestore
        .collection('users')
        .doc(uid)
        .collection('savings_movements');

    final now = DateTime.now();
    final samples = [
      {'amount': 80.0, 'monthsAgo': 1},
      {'amount': 60.0, 'monthsAgo': 2},
      {'amount': 50.0, 'monthsAgo': 3},
      {'amount': 30.0, 'monthsAgo': 4},
    ];

    for (final sample in samples) {
      final amount = sample['amount'] as double;
      final monthsAgo = sample['monthsAgo'] as int;
      final movementDate = DateTime(now.year, now.month - monthsAgo, 10);

      await movementsCol.doc().set({
        'amountUsd': amount,
        'originalAmount': amount,
        'originalCurrency': 'USD',
        'mepRateUsed': null,
        'date': Timestamp.fromDate(movementDate),
      });
    }

    return SeedResult(
      ok: true,
      message: 'Se cargaron ${samples.length} movimientos de ahorro.',
      writtenCount: samples.length,
    );
  } catch (e) {
    return SeedResult(
      ok: false,
      message: 'Error al cargar ahorros: $e',
    );
  }
}

Future<SeedResult> wipeTripsForCurrentUser() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    return const SeedResult(
      ok: false,
      message: 'Tenés que estar logueada.',
    );
  }

  final firestore = FirebaseFirestore.instance;

  try {
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('trips')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    return SeedResult(
      ok: true,
      message: 'Se borraron ${snapshot.docs.length} viajes.',
      writtenCount: snapshot.docs.length,
    );
  } catch (e) {
    return SeedResult(ok: false, message: 'Error al borrar viajes: $e');
  }
}

Future<SeedResult> wipeSavingsForCurrentUser() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    return const SeedResult(
      ok: false,
      message: 'Tenés que estar logueada.',
    );
  }

  final firestore = FirebaseFirestore.instance;

  try {
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('savings_movements')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    return SeedResult(
      ok: true,
      message: 'Se borraron ${snapshot.docs.length} movimientos.',
      writtenCount: snapshot.docs.length,
    );
  } catch (e) {
    return SeedResult(ok: false, message: 'Error al borrar ahorros: $e');
  }
}

List<Map<String, Object>> _tripConfigurations(int availableDestinations) {
  final configs = <Map<String, Object>>[
    {
      'state': TripStatus.presupuesto,
      'monthsAhead': 5,
      'days': 5,
      'people': 2,
      'hotelStars': 4,
      'maxDistanceKm': 3,
      'transport': 'micro',
      'transportCostUsd': 180.0,
      'hotelCostUsd': 240.0,
    },
    {
      'state': TripStatus.presupuesto,
      'monthsAhead': 8,
      'days': 6,
      'people': 2,
      'hotelStars': 3,
      'maxDistanceKm': 2,
      'transport': 'avion',
      'transportCostUsd': 280.0,
      'hotelCostUsd': 180.0,
    },
    {
      'state': TripStatus.activo,
      'monthsAhead': 3,
      'days': 7,
      'people': 2,
      'hotelStars': 3,
      'maxDistanceKm': 2,
      'transport': 'avion',
      'transportCostUsd': 240.0,
      'hotelCostUsd': 140.0,
    },
    {
      'state': TripStatus.completado,
      'monthsAhead': -4,
      'days': 4,
      'people': 1,
      'hotelStars': 2,
      'maxDistanceKm': 1,
      'transport': 'auto',
      'transportCostUsd': 80.0,
      'hotelCostUsd': 90.0,
    },
  ];

  if (availableDestinations < configs.length) {
    return configs.take(availableDestinations).toList();
  }
  return configs;
}
