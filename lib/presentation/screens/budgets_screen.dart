import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../providers/savings_provider.dart';
import '../providers/trip_provider.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  static const String name = 'budgets_screen';

  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(tripProvider.notifier).getBudgets();
      ref.read(savingsProvider.notifier).getAllMovements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final savingsState = ref.watch(savingsProvider);

    return Scaffold(
      backgroundColor: AppColors.pearl,
      appBar: AppBar(title: const Text('Presupuestos')),
      body: _BudgetsBody(
        tripState: tripState,
        totalSavedUsd: savingsState.totalUsd,
      ),
    );
  }
}

class _BudgetsBody extends StatelessWidget {
  final TripState tripState;
  final double totalSavedUsd;

  const _BudgetsBody({
    required this.tripState,
    required this.totalSavedUsd,
  });

  @override
  Widget build(BuildContext context) {
    if (tripState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tripState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            tripState.errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (tripState.budgets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Todavía no tenés presupuestos guardados.\nCreá uno nuevo desde Inicio.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tripState.budgets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final budget = tripState.budgets[index];
        final progress = budget.totalUsd == 0
            ? 0.0
            : (totalSavedUsd / budget.totalUsd).clamp(0.0, 1.0);

        return Card(
          child: ListTile(
            title: Text(budget.destinationName),
            subtitle: Text(
              'USD ${budget.totalUsd.toStringAsFixed(0)} • '
              '${(progress * 100).toStringAsFixed(0)}% ahorrado',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/budgets/${budget.id}'),
          ),
        );
      },
    );
  }
}
