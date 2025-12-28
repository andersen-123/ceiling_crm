import 'package:flutter/material.dart';
import 'package:ceiling_crm/screens/quote_list_screen.dart';
import 'package:ceiling_crm/screens/settings_screen.dart';

void main() {
  runApp(CeilingCRMApp());
}

class CeilingCRMApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ceiling CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        // УБРАНО: fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[800],
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => QuoteListScreen(),
        '/settings': (context) => SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/pdf_preview') {
          final args = settings.arguments;
          // Здесь будет создание экрана предпросмотра PDF
          return MaterialPageRoute(builder: (context) => Container());
        }
        return null;
      },
    );
  }
}
