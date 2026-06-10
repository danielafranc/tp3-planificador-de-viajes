import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/budget_model.dart';
import '../providers/budget_provider.dart';
import '../providers/trip_provider.dart';

class BudgetResultScreen extends ConsumerWidget {
  static const String name = 'presupuesto_screen';
  final BudgetModel budget;

  const BudgetResultScreen({super.key, required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String destino = budget.destination;
    final int personas = budget.passengers;
    final int dias = budget.nights;

    final double totalUSD = budget.totalUSD;
    final double transportUsd = budget.transportUsd;
    final double hotelUsd = budget.hotelUsd;

    final double mep = budget.exchangeRateMEP;
    final double totalARS = totalUSD * mep;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: _buildBody(
          context,
          ref,
          totalUSD,
          totalARS,
          mep,
          destino,
          personas,
          dias,
          transportUsd,
          hotelUsd,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    double totalUSD,
    double totalARS,
    double mep,
    String destino,
    int personas,
    int dias,
    double transportUsd,
    double hotelUsd,
  ) {
    return SafeArea(
      child: Column(
        children: [
          _HeaderSection(
            destino: destino,
            dias: dias,
            personas: personas,
            targetDate: budget.targetDate,
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.pearl,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _MainPriceCard(
                      totalUSD: totalUSD,
                      totalARS: totalARS,
                      mep: mep,
                      personas: personas,
                    ),

                    const SizedBox(height: 24),

                    _ItemRow(
                      icon: _transportIcon(budget.transport),
                      label:
                          '${budget.transport ?? 'Transporte'} ida y vuelta (x$personas)',
                      price: 'USD ${transportUsd.toStringAsFixed(0)}',
                    ),

                    const SizedBox(height: 12),

                    _ItemRow(
                      icon: Icons.hotel,
                      label:
                          'Hotel ${budget.hotelStars ?? 3}★ a ${budget.maxDistanceKm ?? 2}km ($dias noches)',
                      price: 'USD ${hotelUsd.toStringAsFixed(0)}',
                    ),

                    const SizedBox(height: 20),

                    _PerPersonRow(
                      totalUSD: totalUSD,
                      totalARS: totalARS,
                      personas: personas,
                    ),

                    const SizedBox(height: 24),

                    _MetaSection(
                      destino: destino,
                      savingDeadline: budget.savingDeadline,
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: _BotonSecundario(
                            label: 'Volver',
                            onPressed: () => context.go('/new-trip'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _BotonSecundario(
                            label: 'Guardar',
                            onPressed: () async {
                              final ok = await ref
                                  .read(budgetProvider.notifier)
                                  .createBudgetBorrador(
                                    destino: budget.destination,
                                    pasajeros: budget.passengers,
                                    totalUSD: budget.totalUSD,
                                    transportUsd: budget.transportUsd,
                                    hotelUsd: budget.hotelUsd,
                                    nights: budget.nights,
                                    targetDate: budget.targetDate,
                                    savingDeadline: budget.savingDeadline,
                                  );

                              if (!context.mounted) return;

                              if (ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Presupuesto guardado'),
                                  ),
                                );

                                context.go('/budgets');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error al guardar'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _BotonPrimario(
                      label: 'Confirmar como mi viaje',
                      onPressed: () => _showConfirmationDialog(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _transportIcon(String? transport) {
    switch (transport) {
      case 'Micro':
        return Icons.directions_bus;
      case 'Tren':
        return Icons.train;
      default:
        return Icons.flight_takeoff;
    }
  }

  void _showConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 50)),

            const SizedBox(height: 16),

            Text(
              '¡Viaje confirmado!',
              style: AppTextStyles.headerTitle.copyWith(
                color: AppColors.navy,
                fontSize: 22,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Podés ver los detalles en la sección Mi viaje.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),

            const SizedBox(height: 24),

            _BotonPrimario(
              label: 'Ir a Mi viaje',
              onPressed: () async {
                if (budget.id != null) {
                  await ref
                      .read(tripProvider.notifier)
                      .confirmAsActive(budget.id!);
                }
                if (!context.mounted) return;
                context.pop();
                context.go('/my-trip');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _HeaderSection extends StatelessWidget {
  final String destino;
  final int dias, personas;
  final String? targetDate;

  const _HeaderSection({
    required this.destino,
    required this.dias,
    required this.personas,
    this.targetDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Text(
            destino,
            style: AppTextStyles.headerTitle.copyWith(fontSize: 28),
          ),
          Text(
            '$dias días · $personas personas${targetDate != null ? ' · $targetDate' : ''}',
            style: AppTextStyles.headerSubtitle,
          ),
        ],
      ),
    );
  }
}

class _MainPriceCard extends StatelessWidget {
  final double totalUSD, totalARS, mep;
  final int personas;

  const _MainPriceCard({
    required this.totalUSD,
    required this.totalARS,
    required this.mep,
    required this.personas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(
            'USD ${totalUSD.toStringAsFixed(0)}',
            style: AppTextStyles.headerTitle.copyWith(
              color: AppColors.navy,
              fontSize: 42,
            ),
          ),
          Text(
            'precio estimado para $personas personas',
            style: AppTextStyles.fieldLabel,
          ),
          const Divider(height: 30),
          Text(
            '≈ \$${_formatArs(totalARS)} ARS',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
          ),
          Text(
            'Dólar MEP: \$${mep.toStringAsFixed(0)}/USD · actualizado hoy',
            style: AppTextStyles.fieldLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatArs(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
}

class _PerPersonRow extends StatelessWidget {
  final double totalUSD, totalARS;
  final int personas;

  const _PerPersonRow({
    required this.totalUSD,
    required this.totalARS,
    required this.personas,
  });

  String _formatArs(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Por persona', style: AppTextStyles.fieldLabel),
          Text(
            'USD ${(totalUSD / personas).toStringAsFixed(0)} · \$${_formatArs(totalARS / personas)} ARS',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _MetaSection extends StatelessWidget {
  final String destino;
  final String? savingDeadline;

  const _MetaSection({required this.destino, this.savingDeadline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.mauve.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            savingDeadline != null
                ? 'Meta: $savingDeadline (3 meses antes)'
                : 'Meta: por calcular',
            style: AppTextStyles.sectionTitle.copyWith(color: AppColors.navy),
          ),
          const SizedBox(height: 4),
          Text('$destino · destino turístico', style: AppTextStyles.fieldLabel),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final IconData icon;
  final String label, price;

  const _ItemRow({
    required this.icon,
    required this.label,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.mauve, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.fieldLabel)),
        Text(price, style: AppTextStyles.sectionTitle),
      ],
    );
  }
}

class _BotonPrimario extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _BotonPrimario({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mauve,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonText.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}

class _BotonSecundario extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _BotonSecundario({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.mauve),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonText.copyWith(color: AppColors.mauve),
        ),
      ),
    );
  }
}
