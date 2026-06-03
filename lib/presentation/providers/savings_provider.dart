import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/savings_movement.dart';

final savingsProvider = NotifierProvider<SavingsNotifier, SavingsState>(
  SavingsNotifier.new,
);

class SavingsState {
  final bool isLoading;
  final String? errorMessage;
  final List<SavingsMovement> movements;
  final double totalUsd;

  const SavingsState({
    this.isLoading = false,
    this.errorMessage,
    this.movements = const [],
    this.totalUsd = 0.0,
  });

  SavingsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<SavingsMovement>? movements,
    double? totalUsd,
  }) {
    return SavingsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      movements: movements ?? this.movements,
      totalUsd: totalUsd ?? this.totalUsd,
    );
  }
}

class SavingsNotifier extends Notifier<SavingsState> {
  @override
  SavingsState build() {
    return const SavingsState();
  }

  CollectionReference<SavingsMovement>? _movementsCollection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savings_movements')
        .withConverter(
          fromFirestore: SavingsMovement.fromFirestore,
          toFirestore: (SavingsMovement movement, _) => movement.toFirestore(),
        );
  }

  Future<void> getAllMovements() async {
    final collection = _movementsCollection();

    if (collection == null) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada');
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final result = await collection.orderBy('date', descending: true).get();

      final movements = result.docs.map((doc) => doc.data()).toList();
      final total = movements.fold<double>(
        0,
        (acc, movement) => acc + movement.amountUsd,
      );

      state = state.copyWith(
        isLoading: false,
        movements: movements,
        totalUsd: total,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudieron cargar los movimientos.',
        movements: [],
        totalUsd: 0.0,
      );
    }
  }


  Future<void> addMovement({
    required double amount,
    required String currency,
    required double mepRate,
  }) async {

    final collection = _movementsCollection();

    if (collection == null) {
      state = state.copyWith(errorMessage: 'Sesión no iniciada');
      return;
    }
    final amountUsd = (currency == 'USD') ? amount : amount / mepRate;
    final movement = SavingsMovement(
      id: '',
      amountUsd: amountUsd,
      originalAmount: amount,
      originalCurrency: currency,
      mepRateUsed: (currency == 'USD') ? null : mepRate,
      date: DateTime.now(), 
    );

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      await collection.add(movement);
      await getAllMovements(); 
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo registrar el ahorro.',
      );
    }
  }
}
