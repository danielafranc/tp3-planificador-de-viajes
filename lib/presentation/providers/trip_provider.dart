import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../domain/trip.dart';
import 'new_trip_provider.dart';

final tripProvider = NotifierProvider<TripNotifier, TripState>(
  TripNotifier.new,
);

class TripState {
  final bool isLoading;
  final String? errorMessage;
  final List<Trip> budgets;
  final Trip? activeTrip;
  final List<Trip> completed;
  final bool demoInitialized;

  const TripState({
    this.isLoading = false,
    this.errorMessage,
    this.budgets = const [],
    this.activeTrip,
    this.completed = const [],
    this.demoInitialized = false,
  });

  TripState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<Trip>? budgets,
    Trip? activeTrip,
    bool clearActiveTrip = false,
    List<Trip>? completed,
    bool? demoInitialized,
  }) {
    return TripState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      budgets: budgets ?? this.budgets,
      activeTrip: clearActiveTrip ? null : activeTrip ?? this.activeTrip,
      completed: completed ?? this.completed,
      demoInitialized: demoInitialized ?? this.demoInitialized,
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

  void _initDemoIfNeeded() {
    if (!state.demoInitialized) {
      state = state.copyWith(
        isLoading: false,
        budgets: _demoBudgets(),
        activeTrip: _demoActiveTrip(),
        completed: _demoCompleted(),
        demoInitialized: true,
        clearErrorMessage: true,
      );
    }
  }

  Future<void> getBudgets() async {
    if (kUseDemoData) {
      _initDemoIfNeeded();
      return;
    }

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

  List<Trip> _demoBudgets() {
    final now = DateTime.now();
    return [
      Trip(
        id: 'demo-ushuaia',
        destinationId: 'ushuaia',
        destinationName: 'Ushuaia',
        destinationImageUrl: '',
        isTouristic: true,
        state: TripStatus.presupuesto,
        durationDays: 5,
        tripDate: DateTime(2026, 12, 15),
        cheapestMonth: false,
        people: 2,
        hotelStars: 3,
        maxDistanceKm: 2,
        transport: 'avion',
        transportCostUsd: 560,
        hotelCostUsd: 330,
        totalUsd: 890,
        totalArsCache: 890 * 1100,
        mepRateUsed: 1100,
        pricesUpdatedAt: now,
        savingsTargetDate: DateTime(2026, 9, 15),
        createdAt: now,
        confirmedAt: null,
        archivedAt: null,
      ),
      Trip(
        id: 'demo-salta',
        destinationId: 'salta',
        destinationName: 'Salta',
        destinationImageUrl: '',
        isTouristic: true,
        state: TripStatus.presupuesto,
        durationDays: 6,
        tripDate: DateTime(2027, 3, 10),
        cheapestMonth: false,
        people: 2,
        hotelStars: 3,
        maxDistanceKm: 2,
        transport: 'avion',
        transportCostUsd: 280,
        hotelCostUsd: 180,
        totalUsd: 460,
        totalArsCache: 460 * 1100,
        mepRateUsed: 1100,
        pricesUpdatedAt: now,
        savingsTargetDate: DateTime(2026, 12, 10),
        createdAt: now,
        confirmedAt: null,
        archivedAt: null,
      ),
      Trip(
        id: 'demo-mendoza',
        destinationId: 'mendoza',
        destinationName: 'Mendoza',
        destinationImageUrl: '',
        isTouristic: true,
        state: TripStatus.presupuesto,
        durationDays: 5,
        tripDate: DateTime(2026, 10, 12),
        cheapestMonth: false,
        people: 1,
        hotelStars: 3,
        maxDistanceKm: 2,
        transport: 'micro',
        transportCostUsd: 120,
        hotelCostUsd: 200,
        totalUsd: 320,
        totalArsCache: 320 * 1100,
        mepRateUsed: 1100,
        pricesUpdatedAt: now,
        savingsTargetDate: DateTime(2026, 7, 12),
        createdAt: now,
        confirmedAt: null,
        archivedAt: null,
      ),
    ];
  }

  Trip _demoActiveTrip() {
    final now = DateTime.now();
    return Trip(
      id: 'demo-bariloche-active',
      destinationId: 'bariloche',
      destinationName: 'Bariloche',
      destinationImageUrl: '',
      isTouristic: true,
      state: TripStatus.activo,
      durationDays: 7,
      tripDate: DateTime(2026, 7, 15),
      cheapestMonth: false,
      people: 2,
      hotelStars: 3,
      maxDistanceKm: 2,
      transport: 'avion',
      transportCostUsd: 240,
      hotelCostUsd: 140,
      totalUsd: 380,
      totalArsCache: 380 * 1100,
      mepRateUsed: 1100,
      pricesUpdatedAt: now,
      savingsTargetDate: DateTime(2026, 4, 15),
      createdAt: now,
      confirmedAt: now,
      archivedAt: null,
    );
  }

  List<Trip> _demoCompleted() {
    return [
      Trip(
        id: 'demo-tucuman-completed',
        destinationId: 'tucuman',
        destinationName: 'Tucumán',
        destinationImageUrl: '',
        isTouristic: true,
        state: TripStatus.completado,
        durationDays: 4,
        tripDate: DateTime(2026, 1, 15),
        cheapestMonth: false,
        people: 1,
        hotelStars: 2,
        maxDistanceKm: 2,
        transport: 'micro',
        transportCostUsd: 60,
        hotelCostUsd: 110,
        totalUsd: 170,
        totalArsCache: 170 * 1100,
        mepRateUsed: 1100,
        pricesUpdatedAt: DateTime(2026, 1, 1),
        savingsTargetDate: DateTime(2025, 10, 15),
        createdAt: DateTime(2025, 9, 1),
        confirmedAt: DateTime(2025, 9, 5),
        archivedAt: DateTime(2026, 1, 20),
      ),
      Trip(
        id: 'demo-cordoba-completed',
        destinationId: 'cordoba',
        destinationName: 'Córdoba',
        destinationImageUrl: '',
        isTouristic: false,
        state: TripStatus.completado,
        durationDays: 3,
        tripDate: DateTime(2025, 11, 8),
        cheapestMonth: false,
        people: 2,
        hotelStars: 3,
        maxDistanceKm: 1,
        transport: 'auto',
        transportCostUsd: 40,
        hotelCostUsd: 90,
        totalUsd: 130,
        totalArsCache: 130 * 1100,
        mepRateUsed: 1100,
        pricesUpdatedAt: DateTime(2025, 10, 25),
        savingsTargetDate: DateTime(2025, 10, 8),
        createdAt: DateTime(2025, 8, 1),
        confirmedAt: DateTime(2025, 8, 10),
        archivedAt: DateTime(2025, 11, 12),
      ),
    ];
  }

  Future<void> getActiveTrip() async {
    if (kUseDemoData) {
      _initDemoIfNeeded();
      return;
    }

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
    if (kUseDemoData) {
      _initDemoIfNeeded();
      return;
    }

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

  Future<String?> createBudget(TripCalculationResult result) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada');
      return null;
    }

    final now = DateTime.now();
    final totalArs = result.totalUsd * result.mepRate;

    if (kUseDemoData) {
      final demoId = 'demo-${now.millisecondsSinceEpoch}';
      final newTrip = Trip(
        id: demoId,
        destinationId: result.destination.id,
        destinationName: result.destination.name,
        destinationImageUrl: result.destination.imageUrl,
        isTouristic: result.destination.isTouristic,
        state: TripStatus.presupuesto,
        durationDays: result.durationDays,
        tripDate: result.tripDate,
        cheapestMonth: result.cheapestMonth,
        people: result.people,
        hotelStars: result.hotelStars,
        maxDistanceKm: result.maxDistanceKm,
        transport: result.transport,
        transportCostUsd: result.transportCostUsd,
        hotelCostUsd: result.hotelCostUsd,
        totalUsd: result.totalUsd,
        totalArsCache: totalArs,
        mepRateUsed: result.mepRate,
        pricesUpdatedAt: now,
        savingsTargetDate: result.savingsTargetDate,
        createdAt: now,
        confirmedAt: null,
        archivedAt: null,
      );

      state = state.copyWith(
        budgets: [newTrip, ...state.budgets],
        clearErrorMessage: true,
      );

      return demoId;
    }

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trips')
          .add({
            'destinationId': result.destination.id,
            'destinationName': result.destination.name,
            'destinationImageUrl': result.destination.imageUrl,
            'isTouristic': result.destination.isTouristic,
            'state': TripStatus.presupuesto.name,
            'durationDays': result.durationDays,
            'tripDate': result.tripDate == null
                ? null
                : Timestamp.fromDate(result.tripDate!),
            'cheapestMonth': result.cheapestMonth,
            'people': result.people,
            'hotelStars': result.hotelStars,
            'maxDistanceKm': result.maxDistanceKm,
            'transport': result.transport,
            'transportCostUsd': result.transportCostUsd,
            'hotelCostUsd': result.hotelCostUsd,
            'totalUsd': result.totalUsd,
            'totalArsCache': totalArs,
            'mepRateUsed': result.mepRate,
            'pricesUpdatedAt': Timestamp.fromDate(now),
            'savingsTargetDate': Timestamp.fromDate(result.savingsTargetDate),
            'createdAt': Timestamp.fromDate(now),
            'confirmedAt': null,
            'archivedAt': null,
          });

      final newTrip = Trip(
        id: docRef.id,
        destinationId: result.destination.id,
        destinationName: result.destination.name,
        destinationImageUrl: result.destination.imageUrl,
        isTouristic: result.destination.isTouristic,
        state: TripStatus.presupuesto,
        durationDays: result.durationDays,
        tripDate: result.tripDate,
        cheapestMonth: result.cheapestMonth,
        people: result.people,
        hotelStars: result.hotelStars,
        maxDistanceKm: result.maxDistanceKm,
        transport: result.transport,
        transportCostUsd: result.transportCostUsd,
        hotelCostUsd: result.hotelCostUsd,
        totalUsd: result.totalUsd,
        totalArsCache: totalArs,
        mepRateUsed: result.mepRate,
        pricesUpdatedAt: now,
        savingsTargetDate: result.savingsTargetDate,
        createdAt: now,
        confirmedAt: null,
        archivedAt: null,
      );

      state = state.copyWith(
        budgets: [newTrip, ...state.budgets],
        clearErrorMessage: true,
      );

      return docRef.id;
    } catch (e) {
      state = state.copyWith(errorMessage: 'No se pudo guardar el viaje.');
      return null;
    }
  }

  Future<void> delete(String tripId) async {
    if (kUseDemoData) {
      state = state.copyWith(
        budgets: state.budgets.where((trip) => trip.id != tripId).toList(),
        clearErrorMessage: true,
      );
      return;
    }

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
    if (kUseDemoData) {
      final active = state.activeTrip;
      if (active == null || active.id != tripId) {
        state = state.copyWith(errorMessage: 'Viaje activo no encontrado.');
        return;
      }
      final now = DateTime.now();
      final archived = active.copyWith(
        state: TripStatus.completado,
        archivedAt: now,
      );
      state = state.copyWith(
        clearActiveTrip: true,
        completed: [archived, ...state.completed],
        clearErrorMessage: true,
      );
      return;
    }

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
    if (kUseDemoData) {
      final budgetIndex =
          state.budgets.indexWhere((trip) => trip.id == tripId);
      if (budgetIndex == -1) {
        state = state.copyWith(errorMessage: 'Presupuesto no encontrado.');
        return;
      }

      final budgetToConfirm = state.budgets[budgetIndex];
      final newBudgets = List<Trip>.from(state.budgets);
      newBudgets.removeAt(budgetIndex);

      final previousActive = state.activeTrip;
      if (previousActive != null) {
        newBudgets.add(
          previousActive.copyWith(state: TripStatus.presupuesto),
        );
      }

      final now = DateTime.now();
      final newActive = budgetToConfirm.copyWith(
        state: TripStatus.activo,
        confirmedAt: now,
      );

      state = state.copyWith(
        budgets: newBudgets,
        activeTrip: newActive,
        clearErrorMessage: true,
      );
      return;
    }

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

    final updated = current.copyWith(
      people: newPeople,
      transportCostUsd: newTransport,
      totalUsd: newTotal,
      totalArsCache: newArs,
      pricesUpdatedAt: now,
    );

    if (kUseDemoData) {
      final newBudgets = List<Trip>.from(state.budgets);
      newBudgets[index] = updated;
      state = state.copyWith(budgets: newBudgets, clearErrorMessage: true);
      return;
    }

    final collection = _tripsCollection();
    if (collection == null) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada');
      return;
    }

    try {
      await collection.doc(tripId).update({
        'people': newPeople,
        'transportCostUsd': newTransport,
        'totalUsd': newTotal,
        'totalArsCache': newArs,
        'pricesUpdatedAt': Timestamp.fromDate(now),
      });

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
