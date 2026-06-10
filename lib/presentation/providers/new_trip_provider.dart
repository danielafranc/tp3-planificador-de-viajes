import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/destination.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MODELO: resultado del cálculo (se pasa a CalculandoScreen)
// ─────────────────────────────────────────────────────────────────────────────
class TripCalculationResult {
  final String origin;
  final Destination destination;
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
  final double mepRate;
  final DateTime savingsTargetDate;

  const TripCalculationResult({
    required this.origin,
    required this.destination,
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
    required this.mepRate,
    required this.savingsTargetDate,
  });

  double get totalArs => totalUsd * mepRate;
  double get perPersonUsd => totalUsd / people;
  double get perPersonArs => perPersonUsd * mepRate;
}

// ─────────────────────────────────────────────────────────────────────────────
//  ESTADO DEL FORMULARIO
// ─────────────────────────────────────────────────────────────────────────────
class NewTripFormState {
  final String? origin;
  final Destination? destination;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool cheapestMonth;
  final int people;
  final int hotelStars;
  final int maxDistanceKm;
  final String? selectedTransport;
  final Map<String, double> transportPrices;
  final List<String> unavailableTransports;
  final bool isLoadingPrices;
  final bool isCalculating;
  final String? errorMessage;

  const NewTripFormState({
    this.origin,
    this.destination,
    this.dateFrom,
    this.dateTo,
    this.cheapestMonth = false,
    this.people = 1,
    this.hotelStars = 3,
    this.maxDistanceKm = 2,
    this.selectedTransport,
    this.transportPrices = const {},
    this.unavailableTransports = const [],
    this.isLoadingPrices = false,
    this.isCalculating = false,
    this.errorMessage,
  });

  bool get isFormValid =>
      origin != null &&
      origin!.isNotEmpty &&
      destination != null &&
      (cheapestMonth || (dateFrom != null && dateTo != null)) &&
      people > 0 &&
      selectedTransport != null &&
      transportPrices.containsKey(selectedTransport);

  NewTripFormState copyWith({
    String? origin,
    bool clearOrigin = false,
    Destination? destination,
    bool clearDestination = false,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
    bool? cheapestMonth,
    int? people,
    int? hotelStars,
    int? maxDistanceKm,
    String? selectedTransport,
    bool clearSelectedTransport = false,
    Map<String, double>? transportPrices,
    List<String>? unavailableTransports,
    bool? isLoadingPrices,
    bool? isCalculating,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) => NewTripFormState(
    origin: clearOrigin ? null : origin ?? this.origin,
    destination: clearDestination ? null : destination ?? this.destination,
    dateFrom: clearDateFrom ? null : dateFrom ?? this.dateFrom,
    dateTo: clearDateTo ? null : dateTo ?? this.dateTo,
    cheapestMonth: cheapestMonth ?? this.cheapestMonth,
    people: people ?? this.people,
    hotelStars: hotelStars ?? this.hotelStars,
    maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    selectedTransport: clearSelectedTransport
        ? null
        : selectedTransport ?? this.selectedTransport,
    transportPrices: transportPrices ?? this.transportPrices,
    unavailableTransports: unavailableTransports ?? this.unavailableTransports,
    isLoadingPrices: isLoadingPrices ?? this.isLoadingPrices,
    isCalculating: isCalculating ?? this.isCalculating,
    errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONSTANTES INTERNAS
// ─────────────────────────────────────────────────────────────────────────────
const _kTransportBase = {
  'Bariloche': {'Avión': 90.0, 'Micro': 16.0},
  'Ushuaia': {'Avión': 200.0},
  'Mendoza': {'Avión': 70.0, 'Micro': 12.0},
  'Salta': {'Avión': 80.0, 'Micro': 15.0},
  'Iguazú': {'Avión': 110.0, 'Micro': 18.0},
  'Córdoba': {'Avión': 50.0, 'Micro': 8.0, 'Tren': 6.0},
  'Mar del Plata': {'Avión': 45.0, 'Micro': 7.0, 'Tren': 5.0},
  'Rosario': {'Avión': 40.0, 'Micro': 6.0, 'Tren': 4.0},
  'El Calafate': {'Avión': 220.0},
  'Tucumán': {'Avión': 60.0, 'Micro': 10.0},
  'Puerto Madryn': {'Avión': 130.0, 'Micro': 20.0},
};

const _kAllTransports = ['Avión', 'Micro', 'Tren'];
const _kMargen = 1.30;
const _kHotelBasePerNightPerPerson = {
  1: 12.0,
  2: 22.0,
  3: 40.0,
  4: 70.0,
  5: 130.0,
};

// ─────────────────────────────────────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
final newTripProvider = NotifierProvider<NewTripNotifier, NewTripFormState>(
  NewTripNotifier.new,
);

class NewTripNotifier extends Notifier<NewTripFormState> {
  @override
  NewTripFormState build() => const NewTripFormState();

  void setOrigin(String value) =>
      state = state.copyWith(origin: value.isEmpty ? null : value);

  void selectDestination(Destination dest) {
    state = state.copyWith(destination: dest, clearSelectedTransport: true);
    _loadTransportPrices(dest.name);
  }

  void setDateFrom(DateTime? date) =>
      state = state.copyWith(dateFrom: date, clearDateFrom: date == null);

  void setDateTo(DateTime? date) =>
      state = state.copyWith(dateTo: date, clearDateTo: date == null);

  void setCheapestMonth(bool value) => state = state.copyWith(
    cheapestMonth: value,
    clearDateFrom: value,
    clearDateTo: value,
  );

  void setPeople(int n) {
    state = state.copyWith(people: n, clearSelectedTransport: true);
    if (state.destination != null) {
      _loadTransportPrices(state.destination!.name);
    }
  }

  void setHotelStars(int stars) => state = state.copyWith(hotelStars: stars);

  void setMaxDistance(int km) => state = state.copyWith(maxDistanceKm: km);

  void selectTransport(String name) {
    if (!state.unavailableTransports.contains(name)) {
      state = state.copyWith(selectedTransport: name);
    }
  }

  void clearError() => state = state.copyWith(clearErrorMessage: true);

  void resetForm() => state = const NewTripFormState();

  void _loadTransportPrices(String destinationName) {
    state = state.copyWith(
      isLoadingPrices: true,
      transportPrices: {},
      unavailableTransports: [],
    );

    final base = _kTransportBase[destinationName];
    final Map<String, double> prices = {};
    final List<String> unavailable = [];

    for (final transport in _kAllTransports) {
      if (base != null && base.containsKey(transport)) {
        prices[transport] = base[transport]! * _kMargen;
      } else {
        unavailable.add(transport);
      }
    }

    if (base == null) {
      prices['Micro'] = 10.0 * _kMargen;
      unavailable.removeWhere((t) => t == 'Micro');
    }

    state = state.copyWith(
      transportPrices: prices,
      unavailableTransports: unavailable,
      isLoadingPrices: false,
    );
  }

  Future<TripCalculationResult?> calculate() async {
    if (!state.isFormValid) return null;

    state = state.copyWith(isCalculating: true, clearErrorMessage: true);

    try {
      final mep = await _fetchMep();

      // Duración calculada a partir de las fechas (o 180 días si es mes más barato)
      final int durationDays = state.cheapestMonth
          ? 7
          : state.dateTo!.difference(state.dateFrom!).inDays;

      final transportPricePerPerson =
          state.transportPrices[state.selectedTransport]!;
      final transportTotal = transportPricePerPerson * state.people * 2;

      final hotelBase = _kHotelBasePerNightPerPerson[state.hotelStars] ?? 40.0;
      final distFactor = state.maxDistanceKm <= 1
          ? 1.20
          : state.maxDistanceKm <= 2
          ? 1.00
          : state.maxDistanceKm <= 3
          ? 0.85
          : 0.70;
      final hotelTotal =
          hotelBase * distFactor * state.people * durationDays * _kMargen;

      final total = transportTotal + hotelTotal;

      final isTouristic = state.destination!.isTouristic;
      final monthsBefore = isTouristic ? 3 : 1;

      final DateTime referenceDate = state.cheapestMonth
          ? DateTime.now().add(const Duration(days: 180))
          : state.dateFrom!;

      final savingsTarget = DateTime(
        referenceDate.year,
        referenceDate.month - monthsBefore,
        1,
      );

      state = state.copyWith(isCalculating: false);

      return TripCalculationResult(
        origin: state.origin!,
        destination: state.destination!,
        durationDays: durationDays,
        tripDate: state.cheapestMonth ? null : state.dateFrom,
        cheapestMonth: state.cheapestMonth,
        people: state.people,
        hotelStars: state.hotelStars,
        maxDistanceKm: state.maxDistanceKm,
        transport: state.selectedTransport!,
        transportCostUsd: transportTotal,
        hotelCostUsd: hotelTotal,
        totalUsd: total,
        mepRate: mep,
        savingsTargetDate: savingsTarget,
      );
    } catch (e) {
      state = state.copyWith(
        isCalculating: false,
        errorMessage: 'Error al calcular. Verificá tu conexión.',
      );
      return null;
    }
  }

  Future<double> _fetchMep() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.bluelytics.com.ar/v2/latest'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final mepData = data['mep'] as Map<String, dynamic>;
        return (mepData['value_sell'] as num).toDouble();
      }
    } catch (_) {}
    return 1444.0;
  }
}
