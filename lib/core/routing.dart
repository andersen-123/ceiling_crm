import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/estimate_list_screen.dart';
import '../screens/estimate_edit_screen.dart';
import '../screens/calculator_screen.dart';
import '../models/estimate.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/estimates',
      builder: (context, state) => const EstimateListScreen(),
    ),
    GoRoute(
      path: '/estimate_edit',
      builder: (context, state) {
        final Estimate? estimate = state.extra as Estimate?;
        return EstimateEditScreen(estimate: estimate);
      },
    ),
    GoRoute(
      path: '/calculator',
      builder: (context, state) => const CalculatorScreen(),
    ),
  ],
);
