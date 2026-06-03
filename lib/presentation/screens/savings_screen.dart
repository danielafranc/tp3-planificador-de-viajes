import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../providers/savings_provider.dart';
import '../providers/dollar_provider.dart';
import '../widgets/savings/add_savings_form.dart';
import '../widgets/savings/savings_history.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  static const String name = 'savings_screen';
  const SavingsScreen({super.key});
  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(savingsProvider.notifier).getAllMovements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _SavingsHeader(),
            const Expanded(child: _SavingsContent()),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppNavTab.savings),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SavingsHeader extends StatelessWidget {
  const _SavingsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 10, 12),
      color: AppColors.navy,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Mi Ahorro', style: AppTextStyles.headerTitle),
          SizedBox(height: 6),
          Text(
            'Presupuesto acumulado hoy',
            style: AppTextStyles.headerSubtitle,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONTENT
// ─────────────────────────────────────────────────────────────────────────────
class _SavingsContent extends ConsumerWidget {
  const _SavingsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsState = ref.watch(savingsProvider);
    if (savingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _TotalAmountSavings(),
        SizedBox(height: 24),
        AddSavingsForm(),
        SizedBox(height: 24),
        SavingsHistory(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOTAL AMOUNT
// ─────────────────────────────────────────────────────────────────────────────
class _TotalAmountSavings extends ConsumerWidget {
  const _TotalAmountSavings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsState = ref.watch(savingsProvider);
    final mepAsync = ref.watch(dollarMepProvider);
    final mep = mepAsync.value ?? 1444.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(246, 232, 239, 240),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 0, 0, 0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USD ${savingsState.totalUsd.toStringAsFixed(2)}',
            style: AppTextStyles.headerTitle.copyWith(
              color: AppColors.navy,
              fontSize: 32,
            ),
          ),
          const Text(
            'total acumulado en dólares',
            style: TextStyle(color: AppColors.slate, fontSize: 12),
          ),
          const Divider(height: 32, color: AppColors.muted),
          Text(
            '${(savingsState.totalUsd * mep).toStringAsFixed(2)} ARS',
            style: AppTextStyles.headerTitle.copyWith(
              color: AppColors.navy,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dólar MEP: ${mep.toStringAsFixed(2)} USD · actualizado hoy',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
