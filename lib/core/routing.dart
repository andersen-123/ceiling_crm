import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/estimate_list_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/calculator',
      builder: (context, state) => const CalculatorScreen(),
    ),
    GoRoute(
      path: '/estimates',
      builder: (context, state) => const EstimateListScreen(),
    ),
  ],
);
