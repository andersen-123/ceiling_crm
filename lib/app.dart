import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'core/routing.dart';
import 'core/theme.dart';
=======
import 'screens/home_screen.dart';
>>>>>>> d5724ee (Исправлена структура lib (убран lib/lib))

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return MaterialApp.router(
      title: 'Ceiling CRM',
      theme: appTheme,
      routerConfig: router,
=======
    return MaterialApp(
      title: 'Сметы потолков',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
>>>>>>> d5724ee (Исправлена структура lib (убран lib/lib))
    );
  }
}
