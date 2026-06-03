import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_format.dart';
import '../../../domain/savings_movement.dart';
import '../../providers/savings_provider.dart';

class SavingsHistory extends ConsumerWidget {
  const SavingsHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movements = ref.watch(savingsProvider).movements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HISTORIAL', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        for (final movement in movements) HistoryRow(movement: movement),
      ],
    );
  }
}

class HistoryRow extends ConsumerWidget {
  final SavingsMovement movement;
  const HistoryRow({super.key, required this.movement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 95,
            child: Text(
              formatDayMonthYear(movement.date),
              style: const TextStyle(fontSize: 14, color: AppColors.navy),
            ),
          ),
          const SizedBox(width: 50),
          Text(
            '+USD ${movement.amountUsd.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.muted),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    icon: const Icon(Icons.warning_amber_outlined),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('¿Eliminar registro?'),
                    content: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 14),
                        children: [
                          const TextSpan(text: 'Se eliminará el ingreso de '),
                          TextSpan(
                            text: '+USD ${movement.amountUsd.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' del '),
                          TextSpan(
                            text: formatDayMonthYear(movement.date),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(
                            text: '. Esta acción no se puede deshacer.',
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () {
                          ref.read(savingsProvider.notifier).deleteMovement(movement.id);
                          Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.burgundy,
                        ),
                        child: const Text('Eliminar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancelar'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}