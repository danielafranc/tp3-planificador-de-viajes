import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CompletedEmptyState extends StatelessWidget {
  const CompletedEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline,
                color: AppColors.mauve, size: 56),
            SizedBox(height: 16),
            Text(
              'Todavía no archivaste ningún viaje',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Cuando un viaje activo alcance su presupuesto y lo archives desde "Mi Viaje", va a aparecer acá.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
