import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String? id;
  final String destination;
  final int passengers;
  final double totalUSD;
  final double exchangeRateMEP;
  final String status;
  final DateTime? createdAt;
  
  // ← Agregá estos
  final double transportUsd;
  final double hotelUsd;
  final int nights;
  final String? targetDate;      // mes del viaje ej: "abr 2026"
  final String? savingDeadline;  // fecha meta ej: "ene 2026"

  BudgetModel({
    this.id,
    required this.destination,
    required this.passengers,
    required this.totalUSD,
    required this.exchangeRateMEP,
    required this.status,
    this.createdAt,
    required this.transportUsd,
    required this.hotelUsd,
    required this.nights,
    this.targetDate,
    this.savingDeadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'destination': destination,
      'passengers': passengers,
      'totalUSD': totalUSD,
      'exchangeRateMEP': exchangeRateMEP,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      // ← y estos
      'transportUsd': transportUsd,
      'hotelUsd': hotelUsd,
      'nights': nights,
      'targetDate': targetDate,
      'savingDeadline': savingDeadline,
    };
  }

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BudgetModel(
      id: doc.id,
      destination: data['destination'] ?? '',
      passengers: data['passengers'] ?? 1,
      totalUSD: (data['totalUSD'] ?? 0.0).toDouble(),
      exchangeRateMEP: (data['exchangeRateMEP'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Presupuesto',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      // ← y estos
      transportUsd: (data['transportUsd'] ?? 0.0).toDouble(),
      hotelUsd: (data['hotelUsd'] ?? 0.0).toDouble(),
      nights: data['nights'] ?? 1,
      targetDate: data['targetDate'],
      savingDeadline: data['savingDeadline'],
    );
  }
}