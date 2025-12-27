import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _currencySymbol = '₽';
  bool _autoSave = true;
  int _defaultTax = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Внешний вид',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Темная тема'),
                    subtitle: const Text('Включить темный режим'),
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() {
                        _darkMode = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Настройки КП',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Валюта'),
                    subtitle: const Text('Символ валюты для отображения'),
                    trailing: DropdownButton<String>(
                      value: _currencySymbol,
                      items: const [
                        DropdownMenuItem(value: '₽', child: Text('Рубли (₽)')),
                        DropdownMenuItem(value: '\$', child: Text('Доллары (\$)')),
                        DropdownMenuItem(value: '€', child: Text('Евро (€)')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _currencySymbol = value!;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('НДС по умолчанию'),
                    subtitle: const Text('Процент НДС для новых КП'),
                    trailing: DropdownButton<int>(
                      value: _defaultTax,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Без НДС')),
                        DropdownMenuItem(value: 10, child: Text('10%')),
                        DropdownMenuItem(value: 20, child: Text('20%')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _defaultTax = value!;
                        });
                      },
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Автосохранение'),
                    subtitle: const Text('Автоматически сохранять изменения'),
                    value: _autoSave,
                    onChanged: (value) {
                      setState(() {
                        _autoSave = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Данные',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Экспорт данных'),
                    subtitle: const Text('Экспортировать все КП в файл'),
                    onTap: () {
                      _showSnackbar('Экспорт данных в разработке');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Импорт данных'),
                    subtitle: const Text('Импортировать КП из файла'),
                    onTap: () {
                      _showSnackbar('Импорт данных в разработке');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Очистить все данные'),
                    subtitle: const Text('Удалить все КП и настройки'),
                    onTap: () {
                      _showDeleteConfirmation(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'О приложении',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Версия'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Помощь'),
                    onTap: () {
                      _showSnackbar('Раздел помощи в разработке');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Сообщить об ошибке'),
                    onTap: () {
                      _showSnackbar('Отчет об ошибке в разработке');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все данные?'),
        content: const Text('Это действие удалит все коммерческие предложения и настройки. Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackbar('Очистка данных в разработке');
            },
            child: const Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
