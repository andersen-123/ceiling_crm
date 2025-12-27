// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:ceiling_crm/screens/proposals_list_screen.dart';
import 'package:ceiling_crm/screens/create_proposal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const ProposalsListScreen(),
    // Можно добавить другие экраны: DashboardScreen(), ClientsScreen(), etc.
    const Center(child: Text('Статистика (в разработке)')),
    const Center(child: Text('Клиенты (в разработке)')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ceiling CRM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Поиск
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Настройки
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'КП',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Дашборд',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Клиенты',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateProposalScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
