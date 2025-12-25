// Обновляем main.dart для использования реального экрана создания КП

// ЗАМЕНИТЕ ВСЁ СОДЕРЖИМОЕ ФАЙЛА НА ЭТОТ КОД:

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'data/database_helper.dart';
import 'screens/quote_list_screen.dart';
import 'screens/quote_edit_screen.dart'; // Импортируем экран редактирования

void main() {
  runApp(const CeilingCRMApp());
}

class CeilingCRMApp extends StatelessWidget {
  const CeilingCRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ceiling CRM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue.shade800,
          secondary: Colors.blue.shade600,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Экран загрузки (сплэш-скрин) для инициализации БД
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  String _status = 'Инициализация приложения...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Инициализируем базу данных
      setState(() => _status = 'Подготовка базы данных...');
      final dbHelper = DatabaseHelper();
      await dbHelper.database; // Инициализация БД

      // Проверяем, есть ли данные
      setState(() => _status = 'Проверка данных...');
      final quotes = await dbHelper.getAllQuotes();
      final company = await dbHelper.getDefaultCompany();

      await Future.delayed(const Duration(milliseconds: 500)); // Искусственная задержка

      // Переходим на главный экран
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainAppScreen(
            initialQuoteCount: quotes.length,
            companyName: company?.name ?? 'Моя компания',
          ),
        ),
      );
    } catch (error) {
      setState(() => _status = 'Ошибка: $error');
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ErrorScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business_center,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'Ceiling CRM',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Версия 1.1.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Главный экран приложения с навигацией
class MainAppScreen extends StatefulWidget {
  final int initialQuoteCount;
  final String companyName;

  const MainAppScreen({
    super.key,
    required this.initialQuoteCount,
    required this.companyName,
  });

  @override
  MainAppScreenState createState() => MainAppScreenState();
}

class MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;
  int _quoteCount = 0;

  @override
  void initState() {
    super.initState();
    _quoteCount = widget.initialQuoteCount;
  }

  // Экраны для навигации (теперь реальные)
  final List<Widget> _screens = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Инициализируем экраны после того, как контекст доступен
    if (_screens.isEmpty) {
      _screens.addAll([
        const QuoteListScreen(), // Реальный экран списка КП
        const QuoteEditScreen(quote: null), // Реальный экран создания КП
        _buildComingSoonScreen(
          title: 'Настройки',
          icon: Icons.settings,
          description: 'Настройки компании и приложения\nбудут доступны в следующем обновлении',
        ),
      ]);
    }
  }

  // Навигация по нижней панели
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.companyName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('О приложении'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ceiling CRM v1.1.0'),
                      const SizedBox(height: 8),
                      Text('Компания: ${widget.companyName}'),
                      const SizedBox(height: 8),
                      Text('КП в базе: $_quoteCount'),
                      const SizedBox(height: 8),
                      const Text('Готовые функции:'),
                      const SizedBox(height: 4),
                      const Text('• Локальная база данных SQLite'),
                      const Text('• Список коммерческих предложений'),
                      const Text('• Создание и редактирование КП'),
                      const Text('• Работы и оборудование с автоматическим расчетом'),
                      const Text('• Поиск и фильтрация по статусу'),
                      const Text('• Свайп-жесты для удаления'),
                      const SizedBox(height: 8),
                      const Text('В разработке:'),
                      const SizedBox(height: 4),
                      const Text('• Экспорт в PDF и Excel'),
                      const Text('• Настройки компании'),
                      const Text('• Резервное копирование'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'КП',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Создать',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade800,
        onTap: _onItemTapped,
      ),
    );
  }

  // Экран "скоро будет" для недоступных функций
  Widget _buildComingSoonScreen({
    required String title,
    required IconData icon,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Показываем уведомление о том, что функция в разработке
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title будет доступен в следующем обновлении'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: const Icon(Icons.notifications),
              label: const Text('Уведомить о выходе'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Экран ошибки (запасной вариант)
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ошибка'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'Не удалось запустить приложение',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Пожалуйста, перезапустите приложение или проверьте доступ к хранилищу.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const SplashScreen(),
                    ),
                  );
                },
                child: const Text('Попробовать снова'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
