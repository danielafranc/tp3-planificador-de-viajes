import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/savings_provider.dart';
import '../../providers/trip_provider.dart';
import 'budget_summary.dart';
import 'empty_state.dart';
import 'movements_list.dart';
import 'reached_card.dart';
import 'trip_hero.dart';

class MyTripBody extends StatelessWidget {
  final TripState tripState;
  final SavingsState savingsState;
  final Future<void> Function(String tripId) onArchive;

  const MyTripBody({
    super.key,
    required this.tripState,
    required this.savingsState,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    if (tripState.isLoading || savingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tripState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            tripState.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    final trip = tripState.activeTrip;

    if (trip == null) {
      return const MyTripEmptyState();
    }

    final totalSaved = savingsState.totalUsd;
    final progress = trip.totalUsd == 0
        ? 0.0
        : (totalSaved / trip.totalUsd).clamp(0.0, 1.0);
    final reached = totalSaved >= trip.totalUsd && trip.totalUsd > 0;
    final surplus = totalSaved - trip.totalUsd;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        TripHero(trip: trip),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: BudgetSummary(
            totalSaved: totalSaved,
            totalCost: trip.totalUsd,
            progress: progress,
            reached: reached,
            surplus: surplus,
          ),
        ),
        if (reached)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: ReachedCard(
              destinationName: trip.destinationName,
              onArchive: () => onArchive(trip.id),
            ),
          ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'HISTORIAL DEL PRESUPUESTO',
            style: TextStyle(
              color: AppColors.mauve,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        MovementsList(
          movements: savingsState.movements,
          totalCost: trip.totalUsd,
          tripDate: trip.tripDate,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
