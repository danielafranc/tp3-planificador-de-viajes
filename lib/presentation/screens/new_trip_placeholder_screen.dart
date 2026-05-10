import 'package:flutter/material.dart';

class NewTripPlaceholderScreen extends StatelessWidget {
  static const String name = 'new_trip_screen';

  final String? destinationId;

  const NewTripPlaceholderScreen({super.key, this.destinationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo viaje')),
      body: Center(
        child: Text(
          destinationId == null
              ? 'Pantalla Nuevo Viaje pendiente'
              : 'Nuevo viaje para destino: $destinationId',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
