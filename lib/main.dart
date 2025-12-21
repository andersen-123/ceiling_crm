import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/calculator_screen.dart';
import 'database/database_helper.dart';

<<<<<<< HEAD
void main() {
  runApp(const App());
=======
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализируем базу данных
  final databaseHelper = DatabaseHelper.instance;
  await databaseHelper.initDatabase();
  
  // ОБНОВЛЯЕМ ШАБЛОНЫ ДО ВЕРСИИ 3
  await databaseHelper.updateTemplatesTable();
  
  runApp(
    Provider<DatabaseHelper>(
      create: (_) => databaseHelper,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PotolokForLife - Сметы натяжных потолков',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 2,
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      home: const CalculatorScreen(), // СТАРТОВЫЙ ЭКРАН - КАЛЬКУЛЯТОР
      debugShowCheckedModeBanner: false,
    );
  }
>>>>>>> d5724ee (Исправлена структура lib (убран lib/lib))
}

