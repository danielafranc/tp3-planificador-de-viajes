import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/trip.dart';

final tripProvider = NotifierProvider<TripNotifier, TripState>(
  TripNotifier.new,
);

class TripState {
  final bool isLoading;
  final String? errorMessage;
  final List<Trip> budgets;
  final Trip? activeTrip;
  final List<Trip> completed;

  const TripState({
    this.isLoading = false,
    this.errorMessage,
    this.budgets = const [],
    this.activeTrip,
    this.completed = const [],
  });

  TripState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<Trip>? budgets,
    Trip? activeTrip,
    bool clearActiveTrip = false,
    List<Trip>? completed,
  }) {
    return TripState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      budgets: budgets ?? this.budgets,
      activeTrip: clearActiveTrip ? null : activeTrip ?? this.activeTrip,
      completed: completed ?? this.completed,
    );
  }
}

class TripNotifier extends Notifier<TripState> {
  @override
  TripState build() {
    return const TripState();
  }

  CollectionReference<Trip>? _tripsCollection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .withConverter(
          fromFirestore: Trip.fromFirestore,
          toFirestore: (Trip trip, _) => trip.toFirestore(),
        );
  }

  Future<void> getBudgets() async {
    final collection = _tripsCollection();

    if (collection == null) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada');
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final result = await collection
          .where('state', isEqualTo: TripStatus.presupuesto.name)
          .orderBy('createdAt', descending: true)
          .get();

      final budgets = result.docs.map((doc) => doc.data()).toList();

      state = state.copyWith(
        isLoading: false,
        budgets: budgets,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudieron cargar los presupuestos.',
        budgets: [],
      );
    }
  }

  Future<void> getActiveTrip() async {
    final collection = _tripsCollection();

    if (collection == null) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada');
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final result = await collection
          .where('state', isEqualTo: TripStatus.activo.name)
          .limit(1)
          .get();

      final activeTrip =
          result.docs.isEmpty ? null : result.docs.first.data();

      state = state.copyWith(
        isLoading: false,
        activeTrip: activeTrip,
        clearActiveTrip: activeTrip == null,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo cargar el viaje activo.',
      );
    }
  }

  Future<void> getCompleted() async {
    final collection = _tripsCollection();

    if (collection == null) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada');
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final result = await collection
          .where('state', isEqualTo: TripStatus.completado.name)
          .orderBy('archivedAt', descending: true)
          .get();

      final completed = result.docs.map((doc) => doc.data()).toList();

      state = state.copyWith(
        isLoading: false,
        completed: completed,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudieron cargar los viajes completados.',
        completed: [],
      );
    }
  }

  Future<void> delete(String tripId) async {
    final collection = _tripsCollection();

    if (collection == null) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada');
      return;
    }

    try {
      await collection.doc(tripId).delete();

      state = state.copyWith(
        budgets: state.budgets.where((trip) => trip.id != tripId).toList(),
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'No se pudo eliminar el viaje.');
    }
  }

  Future<void> archive(String tripId) async {
    final collection = _tripsCollection();

    if (collection == null) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada');
      return;
    }

    try {
      final now = DateTime.now();

      await collection.doc(tripId).update({
        'state': TripStatus.completado.name,
        'archivedAt': Timestamp.fromDate(now),
      });

      if (state.activeTrip?.id == tripId) {
        state = state.copyWith(
          clearActiveTrip: true,
          clearErrorMessage: true,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'No se pudo archivar el viaje.');
    }
  }

  Future<void> confirmAsActive(String tripId) async {
    final collection = _tripsCollection();

    if (collection == null) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      final activeQuery = await collection
          .where('state', isEqualTo: TripStatus.activo.name)
          .limit(1)
          .get();

      final previousActiveDocId =
          activeQuery.docs.isEmpty || activeQuery.docs.first.id == tripId
              ? null
              : activeQuery.docs.first.id;

      await firestore.runTransaction((transaction) async {
        final now = Timestamp.fromDate(DateTime.now());

        transaction.update(collection.doc(tripId), {
          'state': TripStatus.activo.name,
          'confirmedAt': now,
        });

        if (previousActiveDocId != null) {
          transaction.update(collection.doc(previousActiveDocId), {
            'state': TripStatus.presupuesto.name,
          });
        }
      });

      await Future.wait([getActiveTrip(), getBudgets()]);
    } catch (e) {
      state = state.copyWith(errorMessage: 'No se pudo confirmar el viaje.');
    }
  }

  // STUB hasta que el equipo defina el servicio de pricing.
  // Escala el costo de transporte proporcionalmente y mantiene el hotel.
  Future<void> updatePeople(String tripId, int newPeople) async {
    if (newPeople <= 0) {
      state = state.copyWith(errorMessage: 'Cantidad de personas inválida.');
      return;
    }

    final collection = _tripsCollection();
    if (collection == null) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada');
      return;
    }

    final index = state.budgets.indexWhere((trip) => trip.id == tripId);
    if (index == -1) {
      state = state.copyWith(errorMessage: 'Presupuesto no encontrado.');
      return;
    }

    final current = state.budgets[index];
    final transportPerPerson = current.people == 0
        ? current.transportCostUsd
        : current.transportCostUsd / current.people;
    final newTransport = transportPerPerson * newPeople;
    final newTotal = newTransport + current.hotelCostUsd;
    final newArs = newTotal * current.mepRateUsed;
    final now = DateTime.now();

    try {
      await collection.doc(tripId).update({
        'people': newPeople,
        'transportCostUsd': newTransport,
        'totalUsd': newTotal,
        'totalArsCache': newArs,
        'pricesUpdatedAt': Timestamp.fromDate(now),
      });

      final updated = current.copyWith(
        people: newPeople,
        transportCostUsd: newTransport,
        totalUsd: newTotal,
        totalArsCache: newArs,
        pricesUpdatedAt: now,
      );

      final newBudgets = List<Trip>.from(state.budgets);
      newBudgets[index] = updated;

      state = state.copyWith(budgets: newBudgets, clearErrorMessage: true);
    } catch (e) {
      state = state.copyWith(errorMessage: 'No se pudo actualizar el viaje.');
    }
  }

  // STUB hasta que el equipo defina el servicio de pricing.
  // RN-09: al abrir un presupuesto guardado, los precios se actualizan.
  // Por ahora solo refrescamos pricesUpdatedAt; cuando exista el servicio,
  // acá se recalculan transportCost, hotelCost y mepRate.
  Future<void> refreshPrices(String tripId) async {
    final collection = _tripsCollection();
    if (collection == null) return;

    final now = DateTime.now();

    try {
      await collection.doc(tripId).update({
        'pricesUpdatedAt': Timestamp.fromDate(now),
      });

      final index = state.budgets.indexWhere((trip) => trip.id == tripId);
      if (index != -1) {
        final updated = state.budgets[index].copyWith(pricesUpdatedAt: now);
        final newBudgets = List<Trip>.from(state.budgets);
        newBudgets[index] = updated;
        state = state.copyWith(budgets: newBudgets, clearErrorMessage: true);
      }
    } catch (_) {
      // Silencioso: el refresh es transparente para el usuario.
    }
  }
}
