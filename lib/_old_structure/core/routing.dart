import 'package:flutter/material.dart';
import 'package:ceiling_crm/screens/home_screen.dart';
import 'package:ceiling_crm/screens/calculator_screen.dart';
import 'package:ceiling_crm/screens/estimate_list_screen.dart';
// Временно закомментируйте:
// import 'package:ceiling_crm/screens/estimate_detail_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case '/calculator':
        return MaterialPageRoute(builder: (_) => CalculatorScreen());
      case '/estimates':
        return MaterialPageRoute(builder: (_) => EstimateListScreen());
      // case '/estimate_detail':
      //   final estimate = settings.arguments;
      //   return MaterialPageRoute(
      //     builder: (_) => EstimateDetailScreen(estimate: estimate),
      //   );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Маршрут не найден: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
