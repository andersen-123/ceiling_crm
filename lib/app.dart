import 'package:flutter/material.dart';
import 'core/routing.dart';
import 'core/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ceiling CRM',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
