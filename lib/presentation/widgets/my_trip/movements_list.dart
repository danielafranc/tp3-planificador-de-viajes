import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../domain/savings_movement.dart';

class MovementsList extends StatelessWidget {
  final List<SavingsMovement> movements;
  final double totalCost;
  final DateTime? tripDate;

  const MovementsList({
    super.key,
    required this.movements,
    required this.totalCost,
    required this.tripDate,
  });

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          'Aún no registraste movimientos de ahorro.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      );
    }

    final byMonth = _groupByMonth(movements);
    final monthsAxis = _monthsAxis(byMonth.keys, tripDate);
    final suggestedQuota = _suggestedQuota(totalCost, monthsAxis.length);

    return Column(
      children: [
        for (final monthKey in monthsAxis)
          _MovementRow(
            label: formatMonthKey(monthKey),
            amount: byMonth[monthKey] ?? 0.0,
            dotColor: _dotColor(byMonth[monthKey] ?? 0.0, suggestedQuota),
          ),
      ],
    );
  }

  Map<String, double> _groupByMonth(List<SavingsMovement> movements) {
    final result = <String, double>{};
    for (final m in movements) {
      final key = '${m.date.year}-${m.date.month.toString().padLeft(2, '0')}';
      result[key] = (result[key] ?? 0) + m.amountUsd;
    }
    return result;
  }

  List<String> _monthsAxis(Iterable<String> seenMonths, DateTime? tripDate) {
    final set = <String>{}..addAll(seenMonths);
    if (tripDate != null) {
      set.add('${tripDate.year}-${tripDate.month.toString().padLeft(2, '0')}');
    }
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  double _suggestedQuota(double totalCost, int months) {
    if (months <= 0) return totalCost;
    return totalCost / months;
  }

  Color _dotColor(double amount, double quota) {
    if (amount <= 0) return AppColors.border;
    if (amount >= quota) return const Color(0xFF4E956E);
    if (amount >= quota * 0.5) return const Color(0xFFEB8C3A);
    return AppColors.muted;
  }
}

class _MovementRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color dotColor;

  const _MovementRow({
    required this.label,
    required this.amount,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: amount > 0 ? AppColors.navy : AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            amount > 0 ? '+USD ${amount.toStringAsFixed(0)}' : '\$0',
            style: TextStyle(
              color: amount > 0 ? AppColors.navy : AppColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
