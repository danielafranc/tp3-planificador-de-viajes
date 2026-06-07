import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth_gate_screen.dart';
import '../../presentation/screens/budget_detail_screen.dart';
import '../../presentation/screens/budgets_screen.dart';
import '../../presentation/screens/completed_trips_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/my_trip_screen.dart';
import '../../presentation/screens/new_trip_screen.dart';
import '../../presentation/screens/loading_budget_screen.dart';
import '../../presentation/screens/budget_result_screen.dart';
import '../../domain/budget_model.dart';
import '../../presentation/screens/savings_screen.dart';
import '../../presentation/screens/register_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: AuthGateScreen.name,
      builder: (context, state) => const AuthGateScreen(),
    ),
    GoRoute(
      path: '/register',
      name: RegisterScreen.name,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      name: HomeScreen.name,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/new-trip',
      name: NewTripScreen.name,
      builder: (context, state) {
        final destinationId = state.uri.queryParameters['destinationId'];
        return NewTripScreen(preselectedDestinationId: destinationId);
      },
    ),
    GoRoute(
      path: '/my-trip',
      name: MyTripScreen.name,
      builder: (context, state) => const MyTripScreen(),
    ),
    GoRoute(
      path: '/budgets',
      name: BudgetsScreen.name,
      builder: (context, state) => const BudgetsScreen(),
    ),
    GoRoute(
      path: '/budgets/:id',
      name: BudgetDetailScreen.name,
      builder: (context, state) {
        final budgetId = state.pathParameters['id']!;
        return BudgetDetailScreen(budgetId: budgetId);
      },
    ),
    GoRoute(
      path: '/completed',
      name: CompletedTripsScreen.name,
      builder: (context, state) => const CompletedTripsScreen(),
    ),
    GoRoute(
      path: '/loading_budget',
      name: LoadingBudgetScreen.name,
      builder: (context, state) {
        final formData = state.extra as Map<String, dynamic>?;
        return LoadingBudgetScreen(formData: formData);
      },
    ),
    GoRoute(
      path: '/budget-result',
      name: BudgetResultScreen.name,
      builder: (context, state) {
        final budget = state.extra;
        if (budget == null || budget is! BudgetModel) {
          // Si no hay budget, volvé al inicio
          return const HomeScreen();
        }
        return BudgetResultScreen(budget: budget);
      },
    ),
    GoRoute(
      path: '/savings',
      name: SavingsScreen.name,
      builder: (context, state) => const SavingsScreen(),
    ),
  ],
);
