import 'package:flutter/material.dart';

class BudgetDetailScreen extends StatelessWidget {
  static const String name = 'budget_detail_screen';

  final String budgetId;

  const BudgetDetailScreen({super.key, required this.budgetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de presupuesto')),
      body: Center(child: Text('Detalle del presupuesto: $budgetId')),
    );
  }
}
