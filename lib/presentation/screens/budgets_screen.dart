import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../domain/trip.dart';
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

  Future<void> refresh() async {
    await Future.wait([
      ref.read(tripProvider.notifier).getBudgets(),
      ref.read(savingsProvider.notifier).getAllMovements(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final savingsState = ref.watch(savingsProvider);

    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: _BudgetsBody(
                tripState: tripState,
                totalSavedUsd: savingsState.totalUsd,
                onRefresh: refresh,
                onOpenBudget: (id) => context.push('/budgets/$id'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppNavTab.budgets),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 81,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      color: AppColors.navy,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Presupuestos',
            style: AppTextStyles.headerTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            'Elegí uno para confirmarlo como tu viaje activo',
            style: AppTextStyles.headerSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BudgetsBody extends StatelessWidget {
  final TripState tripState;
  final double totalSavedUsd;
  final Future<void> Function() onRefresh;
  final void Function(String id) onOpenBudget;

  const _BudgetsBody({
    required this.tripState,
    required this.totalSavedUsd,
    required this.onRefresh,
    required this.onOpenBudget,
  });

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

    if (tripState.budgets.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [SizedBox(height: 60), _EmptyState()],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: tripState.budgets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final budget = tripState.budgets[index];
          return _BudgetCard(
            trip: budget,
            totalSavedUsd: totalSavedUsd,
            onTap: () => onOpenBudget(budget.id),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_square,
                color: AppColors.mauve, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Aún no tenés presupuestos guardados',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Creá un presupuesto desde Inicio. Cuando lo guardes va a aparecer acá para que lo revises o lo confirmes como tu viaje activo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () => context.go('/home'),
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

class _BudgetCard extends StatelessWidget {
  final Trip trip;
  final double totalSavedUsd;
  final VoidCallback onTap;

  const _BudgetCard({
    required this.trip,
    required this.totalSavedUsd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = trip.totalUsd == 0
        ? 0.0
        : (totalSavedUsd / trip.totalUsd).clamp(0.0, 1.0);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.mauve.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PhotoArea(trip: trip),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.destinationName,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatSubtitle(trip),
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProgressBar(progress: progress),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'USD ${trip.totalUsd.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const _StatusChip(label: 'presupuesto'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoArea extends StatelessWidget {
  final Trip trip;

  const _PhotoArea({required this.trip});

  @override
  Widget build(BuildContext context) {
    final fallbackColor = _fallbackColorForName(trip.destinationName);

    return SizedBox(
      height: 96,
      child: trip.destinationImageUrl.isEmpty
          ? _PhotoPlaceholder(
              name: trip.destinationName, color: fallbackColor)
          : Image.network(
              trip.destinationImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _PhotoPlaceholder(
                name: trip.destinationName,
                color: fallbackColor,
              ),
            ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final String name;
  final Color color;

  const _PhotoPlaceholder({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: Alignment.center,
      child: Text(
        'foto API — $name',
        style: const TextStyle(
          color: Color(0xFFF3EBDF),
          fontStyle: FontStyle.italic,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final color = _colorForProgress(progress);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Container(height: 8, color: AppColors.border),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(height: 8, color: color),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EDF1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mauve.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.mauve,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _colorForProgress(double progress) {
  if (progress >= 1.0) return const Color(0xFF2E8B57);
  if (progress >= 0.76) return const Color(0xFF8BC34A);
  if (progress >= 0.51) return const Color(0xFFF5C518);
  if (progress >= 0.26) return const Color(0xFFEB8C3A);
  return const Color(0xFFD64545);
}

Color _fallbackColorForName(String name) {
  const palette = [
    AppColors.purpleCard,
    AppColors.warmCard,
    AppColors.blueCard,
    AppColors.greenCard,
    AppColors.slate,
  ];
  return palette[name.hashCode.abs() % palette.length];
}

String _formatSubtitle(Trip trip) {
  final when = trip.tripDate == null
      ? 'mes a definir'
      : _formatMonthYear(trip.tripDate!);
  final personasLabel = trip.people == 1 ? 'persona' : 'personas';
  return '$when · ${trip.durationDays} días · ${trip.people} $personasLabel';
}

String _formatMonthYear(DateTime date) {
  const months = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
