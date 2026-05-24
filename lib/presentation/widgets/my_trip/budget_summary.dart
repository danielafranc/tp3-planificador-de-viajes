import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/progress_bar.dart';

class BudgetSummary extends StatelessWidget {
  final double totalSaved;
  final double totalCost;
  final double progress;
  final bool reached;
  final double surplus;

  const BudgetSummary({
    super.key,
    required this.totalSaved,
    required this.totalCost,
    required this.progress,
    required this.reached,
    required this.surplus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Presupuesto actual: USD ${totalSaved.toStringAsFixed(0)} · '
          'Precio: USD ${totalCost.toStringAsFixed(0)}',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ProgressBar(progress: progress),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              reached
                  ? '✓ Presupuesto alcanzado'
                  : '${(progress * 100).toStringAsFixed(0)}% ahorrado',
              style: TextStyle(
                color: reached ? AppColors.greenCard : AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (reached)
              Text(
                'sobran USD ${surplus.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                'faltan USD ${(totalCost - totalSaved).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
