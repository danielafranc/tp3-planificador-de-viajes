import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/budget_model.dart';
import '../../core/services/dollar_service.dart';

/// Notifier encargado de gestionar la creación de presupuestos
/// y la integración con la API de Dólar MEP.
class BudgetNotifier extends Notifier<AsyncValue<void>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DollarService _dollarService = DollarService();

  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Crea un nuevo presupuesto en Firestore utilizando el valor del MEP en tiempo real.
  Future<bool> createBudgetBorrador({
    required String destino,
    required int pasajeros,
    required double totalUSD,
    required double transportUsd, 
    required double hotelUsd,
    required int nights,
    String? targetDate,
    String? savingDeadline,
  }) async {
    state = const AsyncValue.loading();

    try {
      final double mepReal = await _dollarService.getMepRate();

      final nuevoPresupuesto = BudgetModel(
        destination: destino,
        passengers: pasajeros,
        totalUSD: totalUSD,
        exchangeRateMEP: mepReal,
        status: 'Presupuesto',
        transportUsd: transportUsd, 
        hotelUsd: hotelUsd,
        nights: nights,
        targetDate: targetDate,
        savingDeadline: savingDeadline,
      );

      await _firestore.collection('budgets').add(nuevoPresupuesto.toMap());

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {

      print('Error al guardar: $e');
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
}

final budgetProvider = NotifierProvider<BudgetNotifier, AsyncValue<void>>(
  BudgetNotifier.new,
);
