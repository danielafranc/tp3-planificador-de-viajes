import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/savings_provider.dart';
import '../../providers/dollar_provider.dart';

class AddSavingsForm extends ConsumerStatefulWidget {
  const AddSavingsForm({super.key});

  @override
  ConsumerState<AddSavingsForm> createState() => _AddSavingsFormState();
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
          Row(children: [_currencyButton('USD'), _currencyButton('ARS')]),
          const SizedBox(height: 16),
          Text('Monto en $_currency', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD7BDB8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.burgundy,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isValid ? () {
                      ref.read(savingsProvider.notifier).addMovement(
                            amount: amount,
                            currency: _currency,
                            mepRate: mep,
                          );
                      _amountController.clear();
                    }: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
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
            color: selected ? AppColors.burgundy : AppColors.white,
          ),
          child: Text(
            currency,
            style: TextStyle(
              color: selected ? AppColors.white : AppColors.burgundy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}