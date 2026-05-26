import '../../domain/budget_model.dart';
import 'dollar_service.dart';

class BudgetService {
  static const double _margin = 1.12;

  Future<BudgetModel> calculate({
    required String destination,
    required double transportPricePerPerson,
    required double hotelPricePerNight,
    required int nights,
    required int people,
    required String targetDate,
    required String savingDeadline,
  }) async {
    final mep = await DollarService().getMepRate();

    final transportUsd = transportPricePerPerson * 2 * people * _margin;
    final hotelUsd = hotelPricePerNight * nights * people * _margin;
    final totalUsd = transportUsd + hotelUsd;

    return BudgetModel(
      destination: destination,
      passengers: people,
      totalUSD: totalUsd,
      exchangeRateMEP: mep,
      status: 'Presupuesto',
      transportUsd: transportUsd,
      hotelUsd: hotelUsd,
      nights: nights,
      targetDate: targetDate,
      savingDeadline: savingDeadline,
    );
  }
}