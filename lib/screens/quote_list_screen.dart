// lib/screens/quote_list_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/services/database_helper.dart';
import 'package:ceiling_crm/screens/quote_edit_screen.dart';
import 'package:ceiling_crm/screens/proposal_detail_screen.dart';
import 'package:ceiling_crm/widgets/quote_list_tile.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({super.key});

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Quote> _quotes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  // Загрузка всех КП из базы
  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quotes = await _dbHelper.getAllProposals();
      setState(() {
        _quotes = quotes;
      });
    } catch (e) {
      print('Ошибка загрузки КП: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Фильтрация по поисковому запросу
  List<Quote> get _filteredQuotes {
    if (_searchQuery.isEmpty) return _quotes;
    
    final query = _searchQuery.toLowerCase();
    return _quotes.where((quote) {
      return quote.clientName.toLowerCase().contains(query) ||
          quote.address.toLowerCase().contains(query) ||
          quote.phone.toLowerCase
