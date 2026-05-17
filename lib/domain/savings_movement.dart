import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsMovement {
  final String id;
  final double amountUsd;
  final double originalAmount;
  final String originalCurrency;
  final double? mepRateUsed;
  final DateTime date;

  const SavingsMovement({
    required this.id,
    required this.amountUsd,
    required this.originalAmount,
    required this.originalCurrency,
    required this.mepRateUsed,
    required this.date,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'amountUsd': amountUsd,
      'originalAmount': originalAmount,
      'originalCurrency': originalCurrency,
      'mepRateUsed': mepRateUsed,
      'date': Timestamp.fromDate(date),
    };
  }

  static SavingsMovement fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? {};

    return SavingsMovement(
      id: snapshot.id,
      amountUsd: (data['amountUsd'] as num?)?.toDouble() ?? 0.0,
      originalAmount: (data['originalAmount'] as num?)?.toDouble() ?? 0.0,
      originalCurrency: data['originalCurrency'] ?? 'USD',
      mepRateUsed: (data['mepRateUsed'] as num?)?.toDouble(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
