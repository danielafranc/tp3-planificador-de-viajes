import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/dollar_service.dart';

final dollarServiceProvider = Provider<DollarService>((ref) {
  return DollarService();
});

final dollarMepProvider = FutureProvider<double>((ref) async {
  final service = ref.read(dollarServiceProvider);
  return await service.getMepRate();
});
