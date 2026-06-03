import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../providers/savings_provider.dart';
import '../providers/dollar_provider.dart';
import 'package:flutter/services.dart';
import '../../core/utils/date_format.dart';
import '../../domain/savings_movement.dart';

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
            'Mi Ahorro',
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
        AddSavingsForm(),
        _SavingsHistory(),
      ],
    );
  }
}

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

class AddSavingsForm extends ConsumerStatefulWidget {
  const AddSavingsForm({super.key});

  @override
  ConsumerState<AddSavingsForm>  createState() => _AddSavingsFormState();
}

class _AddSavingsFormState extends ConsumerState<AddSavingsForm> {
  String _currency = 'USD';
  final _amountController = TextEditingController();
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mep = ref.watch(dollarMepProvider).value ?? 1444.0;
    final amount = double.tryParse(_amountController.text) ?? 0;
    final isValid = amount > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(246, 232, 239, 240),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Agregar ahorro', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 14),
          Row(
            children: [
              _currencyButton('USD'),
              _currencyButton('ARS'),
            ],
          ),
          const SizedBox(height: 16),
          Text('Monto en $_currency', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),],
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD7BDB8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF7C2E56), width: 1.4),
              ),
            ),
          ),
           const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isValid ? () {
              final amount = double.tryParse(_amountController.text) ?? 0;
              ref.read(savingsProvider.notifier).addMovement(
                    amount: amount,
                    currency: _currency,
                    mepRate: mep,
                  );
              _amountController.clear();
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C2E56),
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirmar', style: AppTextStyles.buttonText),
          ),
        ),


        ],
      ),
    );
  }

  Widget _currencyButton(String currency) {
    final selected = _currency == currency;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currency = currency;
          });
        },
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7C2E56) : AppColors.white,
          ),
          child: Text(
            currency,
            style: TextStyle(
              color: selected ? AppColors.white : const Color(0xFF7C2E56),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SavingsHistory extends ConsumerWidget {
  const _SavingsHistory();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movements = ref.watch(savingsProvider).movements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HISTORIAL', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        for (final movement in movements)
          _HistoryRow(movement: movement),
      ],
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  final SavingsMovement movement;
  const _HistoryRow({required this.movement});
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
          Expanded(
            child: Text(
              formatDayMonthYear(movement.date),
              style: const TextStyle(fontSize: 14, color: AppColors.navy),
            ),
          ),
          Text(
            '+USD ${movement.amountUsd.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
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
                    content: Text(
                      'Se eliminará el ingreso de +USD ${movement.amountUsd.toStringAsFixed(2)} '
                      'del ${formatDayMonthYear(movement.date)}. Esta acción no se puede deshacer.',
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () {
                          ref.read(savingsProvider.notifier).deleteMovement(movement.id);
                          Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
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