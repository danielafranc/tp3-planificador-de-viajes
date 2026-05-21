import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth_gate_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/new_trip_screen.dart';

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
      name: NewTripScreen.name,
      builder: (context, state) {
        final destinationId = state.uri.queryParameters['destinationId'];
        return NewTripScreen(preselectedDestinationId: destinationId);
      },
    ),
  ],
);
