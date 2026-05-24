import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class MyTripEmptyState extends StatelessWidget {
  const MyTripEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flight_takeoff,
                color: AppColors.mauve, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Todavía no confirmaste un viaje',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Creá un presupuesto desde Inicio y confirmalo como tu viaje activo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () => context.push('/new-trip'),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo viaje'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mauve,
                side: const BorderSide(color: AppColors.mauve),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
