import 'package:flutter/material.dart';
import 'core/routing.dart';
import 'core/theme.dart';

class CeilingCRMApp extends StatelessWidget {
  const CeilingCRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ceiling CRM',
      theme: buildTheme(),
      routerConfig: router,
    );
  }
}
