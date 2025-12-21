import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/estimate_list_screen.dart';
import '../screens/calculator_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/estimates', builder: (context, state) => const EstimateListScreen()),
    GoRoute(path: '/calculator', builder: (context, state) => const CalculatorScreen()),
  ],
);
