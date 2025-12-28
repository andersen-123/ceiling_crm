import 'package:flutter/material.dart';
import 'package:ceiling_crm/screens/quote_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CeilingCRMApp());
}

class CeilingCRMApp extends StatelessWidget {
  const CeilingCRMApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ceiling CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const QuoteListScreen(),
    );
  }
}
