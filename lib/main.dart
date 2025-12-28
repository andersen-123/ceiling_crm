import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/services/database_helper.dart';
import 'package:ceiling_crm/screens/quote_edit_screen.dart';
import 'package:ceiling_crm/screens/settings_screen.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({Key? key}) : super(key: key);

  @override
  _QuoteListScreenState createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  late Future<List<Quote>> _quotesFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  void _loadQuotes() {
    setState(() {
      _quotesFuture = _dbHelper.getAllQuotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Коммерческие предложения'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToEditScreen(null),
            tooltip: 'Создать новое КП',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotes,
            tooltip: 'Обновить список',
          ),
        ],
      ),
      drawer: _buildNavigationDrawer(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditScreen(null),
        child: const Icon(Icons.add),
        tooltip: 'Создать новое КП',
      ),
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Заголовок Drawer
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue, Colors.lightBlue],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 40,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ceiling CRM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black26,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Управление потолками',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Основные разделы
          _buildDrawerSection(
            title: 'Основные',
            icon: Icons.dashboard,
            children: [
              _buildDrawerItem(
                icon: Icons.home,
                title: 'Главная',
                onTap: () {
                  Navigator.pop(context); // Закрываем Drawer
                  // Уже на главной, ничего не делаем
                },
              ),
              _buildDrawerItem(
                icon: Icons.add,
                title: 'Создать КП',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditScreen(null);
                },
              ),
              _buildDrawerItem(
                icon: Icons.list,
                title: 'Все КП',
                onTap: () {
                  Navigator.pop(context);
                  _loadQuotes();
                },
              ),
            ],
          ),

          const Divider(),

          // Настройки
          _buildDrawerSection(
            title: 'Настройки',
            icon: Icons.settings,
            children: [
              _buildDrawerItem(
                icon: Icons.business,
                title: 'Настройки компании',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.palette,
                title: 'Внешний вид',
                onTap: () {
                  Navigator.pop(context);
                  _showAppearanceSettings();
                },
              ),
              _buildDrawerItem(
                icon: Icons.backup,
                title: 'Резервное копирование',
                onTap: () {
                  Navigator.pop(context);
                  _showBackupDialog();
                },
              ),
            ],
          ),

          const Divider(),

          // Помощь
          _buildDrawerSection(
            title: 'Помощь',
            icon: Icons.help,
            children: [
              _buildDrawerItem(
                icon: Icons.help_outline,
                title: 'Справка',
                onTap: () {
                  Navigator.pop(context);
                  _showHelpDialog();
                },
              ),
              _buildDrawerItem(
                icon: Icons.info,
                title: 'О приложении',
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),
              _buildDrawerItem(
                icon: Icons.feedback,
                title: 'Оставить отзыв',
                onTap: () {
                  Navigator.pop(context);
                  _showFeedbackDialog();
                },
              ),
            ],
          ),

          const Divider(),

          // Статистика
          _buildDrawerItem(
            icon: Icons.analytics,
            title: 'Статистика',
            onTap: () {
              Navigator.pop(context);
              _showStatistics();
            },
          ),

          // Экспорт данных
          _buildDrawerItem(
            icon: Icons.file_download,
            title: 'Экспорт данных',
            onTap: () {
              Navigator.pop(context);
              _showExportDialog();
            },
          ),

          const SizedBox(height: 20),

          // Выход
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.exit_to_app, size: 20),
              label: const Text('Выход'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showExitDialog();
              },
            ),
          ),

          // Версия приложения
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Версия 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.blue[700],
      ),
      title: Text(title),
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<Quote>>(
      future: _quotesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final quotes = snapshot.data ?? [];

        if (quotes.isEmpty) {
          return _buildEmptyState();
        }

        return _buildQuoteList(quotes);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Загрузка коммерческих предложений...',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
              onPressed: _loadQuotes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Нет коммерческих предложений',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Создайте свое первое коммерческое предложение для клиента',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Создать первое КП'),
              onPressed: () => _navigateToEditScreen(null),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.help),
              label: const Text('Посмотреть инструкцию'),
              onPressed: _showHelpDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteList(List<Quote> quotes) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadQuotes();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          final quote = quotes[index];
          return _buildQuoteCard(quote);
        },
      ),
    );
  }

  Widget _buildQuoteCard(Quote quote) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToEditScreen(quote.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Иконка статуса
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Информация о КП
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        const Icon(Icons.list, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${quote.items.length} ${_getItemWord(quote.items.length)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(quote.createdAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Сумма
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${quote.totalAmount.toStringAsFixed(2)} руб.',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        
                        // Действия
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _navigateToEditScreen(quote.id),
                              tooltip: 'Редактировать',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () => _showDeleteDialog(quote),
                              tooltip: 'Удалить',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getItemWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'позиция';
    if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return 'позиции';
    }
    return 'позиций';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);
    
    if (dateDay == today) return 'Сегодня';
    if (dateDay == yesterday) return 'Вчера';
    
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _navigateToEditScreen(int? quoteId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteEditScreen(quoteId: quoteId),
      ),
    );
    
    if (result == true) {
      _loadQuotes();
    }
  }

  Future<void> _showDeleteDialog(Quote quote) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить КП?'),
        content: Text('Вы уверены, что хотите удалить КП для "${quote.clientName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dbHelper.deleteQuote(quote.id!);
                _loadQuotes();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('КП "${quote.clientName}" удалено'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка удаления: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // Диалоги из Drawer меню
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Colors.blue),
            SizedBox(width: 8),
            Text('Помощь'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Краткое руководство по использованию Ceiling CRM:\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildHelpItem('1. Создание КП', 'Нажмите "+" или "Создать КП" в меню'),
              _buildHelpItem('2. Заполнение данных', 'Введите информацию о клиенте'),
              _buildHelpItem('3. Добавление позиций', 'Используйте "Быстрое добавление" или добавляйте вручную'),
              _buildHelpItem('4. Сохранение', 'Нажмите "Сохранить" в правом верхнем углу'),
              _buildHelpItem('5. PDF документ', 'Сгенерируйте PDF для отправки клиенту'),
              _buildHelpItem('6. Настройки компании', 'Заполните реквизиты в разделе "Настройки"'),
              const SizedBox(height: 16),
              const Text(
                'Для дополнительной помощи обращайтесь в поддержку.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            description,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('О приложении'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Ceiling CRM',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Версия 1.0.0'),
            const SizedBox(height: 16),
            const Text(
              'CRM система для управления коммерческими предложениями по натяжным потолкам.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Разработано специально для компаний по установке натяжных потолков.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2025 Ceiling CRM',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оставить отзыв'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ваше мнение важно для нас!'),
            SizedBox(height: 8),
            Text(
              'Сообщите о найденных ошибках или предложите улучшения.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Спасибо за ваш отзыв!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // В Flutter Web обычно не выходим
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Выход в веб-версии не доступен'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  void _showAppearanceSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Внешний вид'),
        content: const Text('Настройки внешнего вида будут добавлены в следующей версии.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Резервное копирование'),
        content: const Text('Функция резервного копирования будет добавлена в следующей версии.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика'),
        content: FutureBuilder<List<Quote>>(
          future: _quotesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final quotes = snapshot.data!;
              final totalAmount = quotes.fold(0.0, (sum, quote) => sum + quote.totalAmount);
              final totalItems = quotes.fold(0, (sum, quote) => sum + quote.items.length);
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem('Всего КП:', quotes.length.toString()),
                  _buildStatItem('Общая сумма:', '${totalAmount.toStringAsFixed(2)} руб.'),
                  _buildStatItem('Всего позиций:', totalItems.toString()),
                  _buildStatItem('Средняя сумма КП:', '${(quotes.isNotEmpty ? totalAmount / quotes.length : 0).toStringAsFixed(2)} руб.'),
                  const SizedBox(height: 16),
                  const Text(
                    'Статистика обновляется в реальном времени.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Экспорт данных'),
        content: const Text('Экспорт данных в Excel/CSV будет добавлен в следующей версии.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
