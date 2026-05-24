import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/trip.dart';
import '../providers/savings_provider.dart';
import '../providers/trip_provider.dart';

class BudgetDetailScreen extends ConsumerStatefulWidget {
  static const String name = 'budget_detail_screen';

  final String budgetId;

  const BudgetDetailScreen({super.key, required this.budgetId});

  @override
  ConsumerState<BudgetDetailScreen> createState() =>
      _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends ConsumerState<BudgetDetailScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(tripProvider.notifier).getBudgets();
      await ref.read(tripProvider.notifier).getActiveTrip();
      await ref.read(savingsProvider.notifier).getAllMovements();
      await ref
          .read(tripProvider.notifier)
          .refreshPrices(widget.budgetId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final savingsState = ref.watch(savingsProvider);

    if (tripState.isLoading && tripState.budgets.isEmpty) {
      return const _CenteredScaffold(
        child: CircularProgressIndicator(),
      );
    }

    final budget = _findBudget(tripState.budgets, widget.budgetId);

    if (budget == null) {
      return _CenteredScaffold(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No se encontró el presupuesto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final totalSaved = kUseDemoData ? 420.0 : savingsState.totalUsd;
    final progress = budget.totalUsd == 0
        ? 0.0
        : (totalSaved / budget.totalUsd).clamp(0.0, 1.0);
    final missing = (budget.totalUsd - totalSaved).clamp(0.0, double.infinity);

    final active = tripState.activeTrip;
    final showWarning = active != null && active.id != budget.id;

    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(budget: budget),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _UpdatedPricesBanner(),
                    const SizedBox(height: 18),
                    _DetailRow(
                      label: 'Precio estimado',
                      value: 'USD ${budget.totalUsd.toStringAsFixed(0)}',
                    ),
                    _DetailRow(
                      label: 'Transporte',
                      value:
                          '${_transportLabel(budget.transport)} · Desde USD ${budget.transportCostUsd.toStringAsFixed(0)}',
                    ),
                    _DetailRow(
                      label: 'Hotel',
                      value:
                          '${budget.hotelStars}★ a ${budget.maxDistanceKm}km · Desde USD ${budget.hotelCostUsd.toStringAsFixed(0)}',
                    ),
                    _DetailRow(
                      label: 'Duración',
                      value: '${budget.durationDays} días',
                    ),
                    _PeopleRow(
                      people: budget.people,
                      onEdit: () => _openEditPeopleDialog(budget),
                    ),
                    _DetailRow(
                      label: 'Presupuesto actual',
                      value: 'USD ${totalSaved.toStringAsFixed(0)}',
                    ),
                    _DetailRow(
                      label: 'Falta',
                      value: 'USD ${missing.toStringAsFixed(0)}',
                      valueColor: const Color(0xFFD64545),
                    ),
                    const SizedBox(height: 14),
                    _ProgressBar(progress: progress),
                    const SizedBox(height: 22),
                    if (showWarning) ...[
                      _WarningBanner(activeName: active.destinationName),
                      const SizedBox(height: 20),
                    ],
                    _ConfirmButton(
                      onPressed: () => _onConfirm(budget),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SaveButton(
                            onPressed: () => context.pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DeleteButton(
                            onPressed: () => _onDelete(budget),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Trip? _findBudget(List<Trip> budgets, String id) {
    for (final trip in budgets) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  Future<void> _openEditPeopleDialog(Trip budget) async {
    final newPeople = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => _EditPeopleDialog(budget: budget),
    );

    if (newPeople != null && newPeople != budget.people) {
      await ref.read(tripProvider.notifier).updatePeople(budget.id, newPeople);
    }
  }

  Future<void> _onConfirm(Trip budget) async {
    await ref.read(tripProvider.notifier).confirmAsActive(budget.id);

    if (!mounted) return;

    final error = ref.read(tripProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Viaje confirmado'),
        content: Text(
          'Podés ver los detalles de ${budget.destinationName} en "Mi Viaje".',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mauve,
              foregroundColor: AppColors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.go('/my-trip');
            },
            child: const Text('Ir a Mi Viaje'),
          ),
        ],
      ),
    );
  }

  Future<void> _onDelete(Trip budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('¿Eliminar presupuesto?'),
        content: Text(
          'Se eliminará el presupuesto de ${budget.destinationName}. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD64545),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(tripProvider.notifier).delete(budget.id);

    if (!mounted) return;

    context.pop();
  }
}

class _CenteredScaffold extends StatelessWidget {
  final Widget child;

  const _CenteredScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pearl,
      body: SafeArea(child: Center(child: child)),
    );
  }
}

class _Header extends StatelessWidget {
  final Trip budget;

  const _Header({required this.budget});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _HeaderBackground(budget: budget),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC1F1D22)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 12,
              child: _BackButton(onTap: () => context.pop()),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget.destinationName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatMonthYear(budget.tripDate)} · presupuesto',
                    style: const TextStyle(
                      color: AppColors.peach,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  final Trip budget;

  const _HeaderBackground({required this.budget});

  @override
  Widget build(BuildContext context) {
    if (budget.destinationImageUrl.isEmpty) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.mauve, AppColors.navy],
          ),
        ),
      );
    }

    return Image.network(
      budget.destinationImageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.mauve, AppColors.navy],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.25),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _UpdatedPricesBanner extends StatelessWidget {
  const _UpdatedPricesBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.navy,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Precios actualizados al abrir',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeopleRow extends StatelessWidget {
  final int people;
  final VoidCallback onEdit;

  const _PeopleRow({required this.people, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Personas',
              style: TextStyle(
                color: AppColors.slate,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$people · ',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          InkWell(
            onTap: onEdit,
            child: const Text(
              'Editar',
              style: TextStyle(
                color: AppColors.mauve,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dashed,
              ),
            ),
          ),
        ],
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
          Container(height: 10, color: AppColors.border),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(height: 10, color: color),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String activeName;

  const _WarningBanner({required this.activeName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EDF1),
        border: Border.all(
          color: AppColors.mauve.withValues(alpha: 0.55),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$activeName (tu viaje actual) volverá a Presupuestos y este pasará a ser tu viaje activo.',
        style: const TextStyle(
          color: AppColors.mauve,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ConfirmButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mauve,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Confirmar como mi viaje',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SaveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.mauve,
          side: const BorderSide(color: AppColors.mauve, width: 1.2),
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Guardar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DeleteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFD64545);
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: danger,
          side: const BorderSide(color: danger, width: 1.2),
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Eliminar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _EditPeopleDialog extends StatefulWidget {
  final Trip budget;

  const _EditPeopleDialog({required this.budget});

  @override
  State<_EditPeopleDialog> createState() => _EditPeopleDialogState();
}

class _EditPeopleDialogState extends State<_EditPeopleDialog> {
  late int newPeople;

  @override
  void initState() {
    super.initState();
    newPeople = widget.budget.people;
  }

  @override
  Widget build(BuildContext context) {
    final budget = widget.budget;
    final transportPerPerson = budget.people == 0
        ? budget.transportCostUsd
        : budget.transportCostUsd / budget.people;
    final newTransport = transportPerPerson * newPeople;
    final newTotal = newTransport + budget.hotelCostUsd;

    return AlertDialog(
      title: const Text('Editar personas'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: newPeople > 1
                    ? () => setState(() => newPeople--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 32,
                color: AppColors.mauve,
              ),
              const SizedBox(width: 16),
              Text(
                '$newPeople',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => setState(() => newPeople++),
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 32,
                color: AppColors.mauve,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nuevo precio estimado',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'USD ${newTotal.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mauve,
            foregroundColor: AppColors.white,
          ),
          onPressed: () => Navigator.of(context).pop(newPeople),
          child: const Text('Guardar'),
        ),
      ],
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

String _transportLabel(String transport) {
  switch (transport) {
    case 'avion':
      return 'Avión';
    case 'micro':
      return 'Micro';
    case 'auto':
      return 'Auto';
    case 'tren':
      return 'Tren';
    default:
      return transport.isEmpty
          ? '—'
          : '${transport[0].toUpperCase()}${transport.substring(1)}';
  }
}

String _formatMonthYear(DateTime? date) {
  if (date == null) return 'fecha a definir';
  const months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
