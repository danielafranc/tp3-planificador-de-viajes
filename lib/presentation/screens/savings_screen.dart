import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../providers/savings_provider.dart';

class SavingsScreen extends ConsumerWidget {
static const String name = 'savings_screen';
const SavingsScreen({super.key});

@override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _SavingsHeader(),
            const Expanded(
              child: _SavingsContent(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppNavTab.savings),
    );
  }
}

class _SavingsHeader extends StatelessWidget{
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
          Text(
            'Mis Ahorros',
            style: AppTextStyles.headerTitle,
          ),
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


class _SavingsContent extends StatelessWidget {
  const _SavingsContent();

 @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _TotalAmountSavings(),
        SizedBox(height: 24),
      ],
    );
  }
}



class _TotalAmountSavings extends ConsumerWidget {
  const _TotalAmountSavings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsState = ref.watch(savingsProvider);
    //final dolarMEP = ref.watch(newTripProvider.notifier).fetchMep();

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
            //me falta usar el valor del dolar
            '${(savingsState.totalUsd) } ARS',
            style: AppTextStyles.headerTitle.copyWith(
              color: AppColors.navy, 
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Dólar MEP: \$1.444/USD · actualizado hoy', 
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}