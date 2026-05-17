import 'package:flutter/material.dart';

class CompletedTripsScreen extends StatelessWidget {
  static const String name = 'completed_trips_screen';

  const CompletedTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completados')),
      body: const Center(child: Text('Pantalla Completados pendiente')),
    );
  }
}
