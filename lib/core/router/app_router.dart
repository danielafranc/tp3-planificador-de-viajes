import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth_gate_screen.dart';
import '../../presentation/screens/budget_detail_screen.dart';
import '../../presentation/screens/budgets_screen.dart';
import '../../presentation/screens/completed_trips_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/my_trip_screen.dart';
import '../../presentation/screens/new_trip_placeholder_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: AuthGateScreen.name,
      builder: (context, state) => const AuthGateScreen(),
    ),
    GoRoute(
      path: '/home',
      name: HomeScreen.name,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/new-trip',
      name: NewTripPlaceholderScreen.name,
      builder: (context, state) {
        final destinationId = state.uri.queryParameters['destinationId'];

        return NewTripPlaceholderScreen(destinationId: destinationId);
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
  ],
);
