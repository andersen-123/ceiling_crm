import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../data/database_helper.dart';
import '../services/excel_service.dart';
import '../widgets/export_all_dialog.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  StatsScreenState createState() => StatsScreenState();
}

class StatsScreenState extends State<StatsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ExcelService _excelService = ExcelService();
  
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentQuotes = [];
  List<Map<String, dynamic>> _monthlyStats = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      // Основная статистика
      final quotes = await _dbHelper.getAllQuotes();
      
      // Расчет статистики
      double totalAmount = 0;
      int draftCount = 0;
      int sentCount = 0;
      int approvedCount = 0;
      int completedCount = 0;
      
      // Статистика по месяцам
      final monthlyMap = <String, double>{};
      
      for (final quote in quotes) {
        totalAmount += quote.totalAmount;
        
        // Статистика по статусам
        switch (quote.status) {
          case 'draft':
            draftCount++;
            break;
          case 'sent':
            sentCount++;
            break;
          case 'approved':
            approvedCount++;
            break;
          case 'completed':
            completedCount++;
            break;
        }
        
        // Статистика по месяцам
        final monthKey = '${quote.createdAt.year}-${quote.createdAt.month.toString().padLeft(2, '0')}';
        monthlyMap[monthKey] = (monthlyMap[monthKey] ?? 0) + quote.totalAmount;
      }
      
      // Преобразуем статистику по месяцам
      _monthlyStats = monthlyMap.entries.map((entry) {
        final parts = entry.key.split('-');
        return {
          'month': '${parts[1]}/${parts[0]}',
          'amount': entry.value,
        };
      }).toList()
        ..sort((a, b) => b['month'].compareTo(a['month'])); // Сортируем по убыванию даты
      
      // Последние КП
      _recentQuotes = quotes
          .take(5)
          .map((quote) => {
                'id': quote.id,
                'customer': quote.customerName,
                'amount': quote.totalAmount,
                'date': quote.createdAt,
                'status': quote.status,
              })
          .toList();
      
      _stats = {
        'totalQuotes': quotes.length,
        'totalAmount': totalAmount,
        'draftCount': draftCount,
        'sentCount': sentCount,
        'approvedCount': approvedCount,
        'completedCount': completedCount,
        'avgAmount': quotes.isNotEmpty ? totalAmount / quotes.length : 0,
      };
      
    } catch (error) {
      print('Ошибка загрузки статистики: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // График по месяцам
  Widget _buildMonthlyChart() {
    if (_monthlyStats.isEmpty) {
      return const Center(
        child: Text('Нет данных для графика'),
      );
    }
    
    final series = [
      charts.Series<Map<String, dynamic>, String>(
        id: 'Выручка',
        domainFn: (data, _) => data['month'] as String,
        measureFn: (data, _) => data['amount'] as double,
        data: _monthlyStats,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        labelAccessorFn: (data, _) => '${(data['amount'] as double).toStringAsFixed(0)} ₽',
      ),
    ];
    
    return SizedBox(
      height: 200,
      child: charts.BarChart(
        series,
        animate: true,
        vertical: false,
        barRendererDecorator: charts.BarLabelDecorator<String>(
          labelPosition: charts.BarLabelPosition.inside,
          insideLabelStyleSpec: const charts.TextStyleSpec(
            fontSize: 10,
            color: charts.MaterialPalette.white,
          ),
        ),
        domainAxis: const charts.OrdinalAxisSpec(
          renderSpec: charts.SmallTickRendererSpec(
            labelStyle: charts.TextStyleSpec(fontSize: 10),
          ),
        ),
      ),
    );
  }

  // Карточка со статистикой
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Список последних КП
  Widget _buildRecentQuotes() {
    if (_recentQuotes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Нет коммерческих предложений'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Последние КП',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._recentQuotes.map((quote) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quote['customer'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${_formatDate(quote['date'] as DateTime)} • ${_getStatusText(quote['status'] as String)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(quote['amount'] as double).toStringAsFixed(2)} ₽',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'draft': return 'Черновик';
      case 'sent': return 'Отправлено';
      case 'approved': return 'Согласовано';
      case 'completed': return 'Выполнено';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const ExportAllDialog(),
            ),
            tooltip: 'Экспорт всех КП',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Основная статистика
                  const Text(
                    'Общая статистика',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _buildStatCard(
                        'Всего КП',
                        _stats['totalQuotes'].toString(),
                        Icons.description,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Общая сумма',
                        '${_stats['totalAmount'].toStringAsFixed(2)} ₽',
                        Icons.attach_money,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Средний чек',
                        '${_stats['avgAmount'].toStringAsFixed(2)} ₽',
                        Icons.assessment,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Выполнено',
                        _stats['completedCount'].toString(),
                        Icons.check_circle,
                        Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Статистика по статусам
                  const Text(
                    'Статусы КП',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatusRow('Черновики', _stats['draftCount'], Colors.grey),
                          _buildStatusRow('Отправлено', _stats['sentCount'], Colors.orange),
                          _buildStatusRow('Согласовано', _stats['approvedCount'], Colors.green),
                          _buildStatusRow('Выполнено', _stats['completedCount'], Colors.blue),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // График по месяцам
                  const Text(
                    'Выручка по месяцам',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildMonthlyChart(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Последние КП
                  _buildRecentQuotes(),

                  const SizedBox(height: 32),

                  // Кнопка экспорта
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const ExportAllDialog(),
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Экспортировать все КП в Excel'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
