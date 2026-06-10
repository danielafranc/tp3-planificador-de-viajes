import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String? id;
  final String destination;
  final int passengers;
  final double totalUSD;
  final double exchangeRateMEP;
  final String status;
  final DateTime? createdAt;
  final double transportUsd;
  final double hotelUsd;
  final int nights;
  final String? targetDate;
  final String? savingDeadline;
  final String? transport;
  final int? hotelStars;
  final int? maxDistanceKm;

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
    this.transport,
    this.hotelStars,
    this.maxDistanceKm,
  });

  Map<String, dynamic> toMap() {
    return {
      'destination': destination,
      'passengers': passengers,
      'totalUSD': totalUSD,
      'exchangeRateMEP': exchangeRateMEP,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'transportUsd': transportUsd,
      'hotelUsd': hotelUsd,
      'nights': nights,
      'targetDate': targetDate,
      'savingDeadline': savingDeadline,
      'transport': transport,
      'hotelStars': hotelStars,
      'maxDistanceKm': maxDistanceKm,
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
      transportUsd: (data['transportUsd'] ?? 0.0).toDouble(),
      hotelUsd: (data['hotelUsd'] ?? 0.0).toDouble(),
      nights: data['nights'] ?? 1,
      targetDate: data['targetDate'],
      savingDeadline: data['savingDeadline'],
      transport: data['transport'],
      hotelStars: data['hotelStars'],
      maxDistanceKm: data['maxDistanceKm'],
    );
  }
}
