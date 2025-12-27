// lib/app.dart
import 'package:flutter/material.dart';
import 'package:ceiling_crm/screens/home_screen.dart';
import 'package:ceiling_crm/screens/quote_list_screen.dart';
import 'package:ceiling_crm/screens/quote_edit_screen.dart';
import 'package:ceiling_crm/screens/proposal_detail_screen.dart';
import 'package:ceiling_crm/screens/settings_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _selectedIndex = 0;

  // Статический список виджетов для bottom navigation
  static final List<Widget> _widgetOptions = <Widget>[
    const QuoteListScreen(), // Главный экран - список КП
    // Здесь можно добавить другие экраны
    Container(), // Заглушка для второго пункта
    const SettingsScreen(), // Настройки
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            label: 'Статистика',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 
          ? FloatingActionButton(
              onPressed: () {
                // Переход на создание нового КП
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuoteEditScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
