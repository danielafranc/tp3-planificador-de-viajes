import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/trip_provider.dart';
import 'completed_card.dart';
import 'completed_empty_state.dart';

class CompletedBody extends StatelessWidget {
  final TripState tripState;

  const CompletedBody({super.key, required this.tripState});

  @override
  Widget build(BuildContext context) {
    if (tripState.isLoading) {
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

    if (tripState.completed.isEmpty) {
      return const CompletedEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: tripState.completed.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final trip = tripState.completed[index];
        return CompletedCard(trip: trip);
      },
    );
  }
}
