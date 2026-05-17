import 'package:flutter/material.dart';

class MyTripScreen extends StatelessWidget {
  static const String name = 'my_trip_screen';

  const MyTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Viaje')),
      body: const Center(child: Text('Pantalla Mi Viaje pendiente')),
    );
  }
}
