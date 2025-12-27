// lib/main.dart
import 'package:flutter/material.dart';
import 'package:ceiling_crm/screens/home_screen.dart';
import 'package:ceiling_crm/screens/proposals_list_screen.dart';
import 'package:ceiling_crm/screens/create_proposal_screen.dart';
import 'package:ceiling_crm/screens/proposal_detail_screen.dart';
import 'package:ceiling_crm/screens/edit_position_modal.dart';
import 'package:ceiling_crm/screens/pdf_preview_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ceiling CRM',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const HomeScreen(), // ИЛИ const ProposalsListScreen(), если HomeScreen нет
      routes: {
        '/home': (context) => const HomeScreen(),
        '/proposals': (context) => const ProposalsListScreen(),
        '/create': (context) => const CreateProposalScreen(),
        '/detail': (context) => ProposalDetailScreen(proposal: {}), // Заглушка
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
