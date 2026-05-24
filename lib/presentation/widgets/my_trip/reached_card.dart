import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ReachedCard extends StatelessWidget {
  final String destinationName;
  final VoidCallback onArchive;

  const ReachedCard({
    super.key,
    required this.destinationName,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F4EE),
        border: Border.all(color: const Color(0xFF8BC9A6), width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Text(
                'Alcanzado',
                style: TextStyle(
                  color: Color(0xFF2E8B57),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ya tenés el presupuesto para ir a $destinationName.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onArchive,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mauve,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Archivar viaje',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
