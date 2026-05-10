import 'package:cloud_firestore/cloud_firestore.dart';

class Destination {
  final String id;
  final String name;
  final String province;
  final String description;
  final String imageUrl;
  final double priceFromUsd;
  final bool isFeatured;
  final bool isTouristic;
  final List<String> availableTransports;

  Destination({
    required this.id,
    required this.name,
    required this.province,
    required this.description,
    required this.imageUrl,
    required this.priceFromUsd,
    required this.isFeatured,
    required this.isTouristic,
    required this.availableTransports,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'province': province,
      'description': description,
      'imageUrl': imageUrl,
      'priceFromUsd': priceFromUsd,
      'isFeatured': isFeatured,
      'isTouristic': isTouristic,
      'availableTransports': availableTransports,
    };
  }

  static Destination fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? {};

    return Destination(
      id: snapshot.id,
      name: data['name'] ?? '',
      province: data['province'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      priceFromUsd: _toDouble(data['priceFromUsd']),
      isFeatured: data['isFeatured'] ?? false,
      isTouristic: data['isTouristic'] ?? false,
      availableTransports: _toStringList(data['availableTransports']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    return 0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }
}
