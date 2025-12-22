import 'package:flutter/material.dart';
import 'package:ceiling_crm/screens/project_finance_screen.dart';
import 'package:ceiling_crm/screens/estimate_edit_screen.dart';
import 'package:ceiling_crm/screens/transaction_screen.dart';
import 'package:ceiling_crm/database/database_helper.dart';
import 'package:ceiling_crm/models/project.dart';
import 'package:ceiling_crm/models/estimate.dart';
import 'package:ceiling_crm/models/transaction.dart';
import 'package:ceiling_crm/utils/salary_calculator.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Transaction> _transactions = [];
  Estimate? _estimate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Загружаем транзакции
      _transactions = await _dbHelper.getProjectTransactions(_project.id!);
      
      // Обновляем расчёт зарплаты
      SalaryCalculator.updateProjectSalary(_project, _transactions);
      
      // Обновляем проект в базе
      await _dbHelper.updateProject(_project);
      
      setState(() {});
    } catch (e) {
      print('Ошибка загрузки данных: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToFinance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectFinanceScreen(
          project: _project,
          transactions: _transactions,
        ),
      ),
    );
  }

  void _navigateToEstimate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EstimateEditScreen(
          estimate: _estimate ?? Estimate(
            title: 'Смета для ${_project.title}',
            items: [],
            createdAt: DateTime.now(),
          ),
          projectId: _project.id,
        ),
      ),
    );
  }

  void _navigateToTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionScreen(
          projectId: _project.id!,
          onTransactionAdded: _loadData,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _project.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    _getStatusText(_project.status),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(_project.status),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Сумма договора', '${_project.contractSum.toStringAsFixed(2)} ₽'),
            _buildInfoRow('Получено аванса', '${_project.prepaymentReceived.toStringAsFixed(2)} ₽'),
            _buildInfoRow('Бригада', '${_project.workers.length} чел.'),
            if (_project.driver != null)
              _buildInfoRow('Водитель', _project.driver!.name),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Финансы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFinanceRow('Доходы', _project.contractSum, Colors.green),
            _buildFinanceRow('Расходы', _project.totalExpenses, Colors.red),
            const Divider(height: 20),
            _buildFinanceRow(
              'Баланс',
              _project.balance,
              _project.balance >= 0 ? Colors.green : Colors.red,
              isBold: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToFinance,
                icon: const Icon(Icons.attach_money),
                label: const Text('Детальный финансовый отчёт'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Быстрые действия',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildActionButton(
                  icon: Icons.receipt_long,
                  label: 'Смета',
                  color: Colors.blue,
                  onTap: _navigateToEstimate,
                ),
                _buildActionButton(
                  icon: Icons.account_balance_wallet,
                  label: 'Транзакции',
                  color: Colors.green,
                  onTap: _navigateToTransactions,
                ),
                _buildActionButton(
                  icon: Icons.groups,
                  label: 'Бригада',
                  color: Colors.orange,
                  onTap: () {
                    // TODO: Экран бригады
                  },
                ),
                _buildActionButton(
                  icon: Icons.description,
                  label: 'Отчёт',
                  color: Colors.purple,
                  onTap: () {
                    // TODO: Генерация отчёта
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recent = _transactions.take(3).toList();
    
    if (recent.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Последние операции',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Нет транзакций',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _navigateToTransactions,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить операцию'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Последние операции',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _navigateToTransactions,
                  child: const Text('Все'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recent.map((transaction) => _buildTransactionTile(transaction)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, double value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          )),
          Text(
            '${value.toStringAsFixed(2)} ₽',
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: transaction.isIncome ? Colors.green : Colors.red,
        child: Icon(
          transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(transaction.category),
      subtitle: Text(
        transaction.date.toString().substring(0, 10),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '${transaction.amount.toStringAsFixed(2)} ₽',
        style: TextStyle(
          color: transaction.isIncome ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'plan': return Colors.blue;
      case 'active': return Colors.green;
      case 'completed': return Colors.grey;
      case 'paid': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'plan': return 'Планирование';
      case 'active': return 'В работе';
      case 'completed': return 'Завершён';
      case 'paid': return 'Оплачен';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали проекта'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildFinanceCard(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 16),
                  _buildRecentTransactions(),
                ],
              ),
            ),
    );
  }
}
