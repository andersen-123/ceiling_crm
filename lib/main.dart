// Главный файл приложения Ceiling CRM
// Инициализирует базу данных и запускает базовую навигацию

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'data/database_helper.dart';

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
            companyName: company?.name ?? 'Компания',
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
              'Версия 1.0.0',
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

// Главный экран приложения (заглушка на время разработки)
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

  // Навигация по нижней панели
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Статические заглушки для экранов (будут заменены в следующих этапах)
  static final List<Widget> _widgetOptions = <Widget>[
    _buildPlaceholderScreen(
      title: 'Список КП',
      icon: Icons.list_alt,
      description: 'Здесь будет список коммерческих предложений',
      actionText: 'Добавить тестовое КП',
      onAction: () {},
    ),
    _buildPlaceholderScreen(
      title: 'Создать КП',
      icon: Icons.add_circle_outline,
      description: 'Здесь будет форма создания нового КП',
      actionText: 'Открыть конструктор',
      onAction: () {},
    ),
    _buildPlaceholderScreen(
      title: 'Настройки',
      icon: Icons.settings,
      description: 'Здесь будут настройки компании и приложения',
      actionText: 'Настроить компанию',
      onAction: () {},
    ),
  ];

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
                      const Text('Ceiling CRM v1.0.0'),
                      const SizedBox(height: 8),
                      Text('Компания: ${widget.companyName}'),
                      const SizedBox(height: 8),
                      Text('КП в базе: $_quoteCount'),
                      const SizedBox(height: 8),
                      const Text('Этап разработки: Ядро данных готово'),
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
      body: _widgetOptions.elementAt(_selectedIndex),
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

  // Вспомогательный метод для создания экранов-заглушек
  static Widget _buildPlaceholderScreen({
    required String title,
    required IconData icon,
    required String description,
    required String actionText,
    required VoidCallback onAction,
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
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward),
              label: Text(actionText),
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

// Простой виджет для отображения статуса базы данных (для тестирования)
class DatabaseStatusWidget extends StatelessWidget {
  const DatabaseStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Database>(
      future: DatabaseHelper().database,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Загрузка базы данных...'),
          );
        }

        if (snapshot.hasError) {
          return ListTile(
            leading: const Icon(Icons.error, color: Colors.red),
            title: const Text('Ошибка базы данных'),
            subtitle: Text('${snapshot.error}'),
          );
        }

        return const ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text('База данных готова'),
          subtitle: Text('SQLite инициализирован успешно'),
        );
      },
    );
  }
}
