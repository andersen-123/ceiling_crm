import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/project.dart';
import 'package:ceiling_crm/models/transaction.dart';
import 'package:ceiling_crm/utils/salary_calculator.dart';

class ProjectFinanceScreen extends StatefulWidget {
  final Project project;
  final List<Transaction> transactions;

  const ProjectFinanceScreen({
    super.key,
    required this.project,
    required this.transactions,
  });

  @override
  State<ProjectFinanceScreen> createState() => _ProjectFinanceScreenState();
}

class _ProjectFinanceScreenState extends State<ProjectFinanceScreen> {
  late Project _project;
  late List<Transaction> _transactions;
  Map<String, dynamic>? _salaryCalculation;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _transactions = widget.transactions;
    _calculateSalary();
  }

  void _calculateSalary() {
    _salaryCalculation = SalaryCalculator.calculateSalary(
      contractSum: _project.contractSum,
      transactions: _transactions,
      workers: _project.workers,
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _project.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Сумма договора:'),
                Text(
                  '${_project.contractSum.toStringAsFixed(2)} ₽',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Получено аванса:'),
                Text(
                  '${_project.prepaymentReceived.toStringAsFixed(2)} ₽',
                  style: TextStyle(
                    color: _project.prepaymentReceived > 0 ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            if (_project.driver != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Водитель:'),
                  Text(
                    _project.driver!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceSummary() {
    final expenses = _salaryCalculation?['expenses_by_category'] as Map<String, double>? ?? {};
    final totalExpenses = expenses.values.fold(0.0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Финансовая сводка',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Доходы
            _buildFinanceRow(
              label: 'Общие доходы',
              value: _project.contractSum,
              isHeader: true,
            ),
            
            // Расходы
            _buildFinanceRow(
              label: 'Общие расходы',
              value: totalExpenses,
              isExpense: true,
              isHeader: true,
            ),
            
            // Баланс
            _buildFinanceRow(
              label: 'Баланс',
              value: _project.contractSum - totalExpenses,
              isBold: true,
              color: (_project.contractSum - totalExpenses) >= 0 ? Colors.green : Colors.red,
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // Детализация расходов
            if (expenses.isNotEmpty) ...[
              const Text(
                'Детализация расходов:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              ...expenses.entries.map((entry) => 
                _buildExpenseDetail(entry.key, entry.value)
              ),
              
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryCalculation() {
    if (_salaryCalculation == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final salaries = _salaryCalculation!['worker_salaries'] as Map<String, double>;
    final gasoline = _salaryCalculation!['gasoline_expense'] as double;
    final materials = _salaryCalculation!['materials_expense'] as double;
    final amortization = _salaryCalculation!['amortization'] as double;
    final driverName = _salaryCalculation!['driver_name'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Расчёт зарплаты по формуле',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Формула
            const Text(
              'Формула: 100% - бензин - материалы - 5% амортизация → делим на всех',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Этапы расчёта
            _buildCalculationStep('1. Сумма договора:', _project.contractSum),
            _buildCalculationStep('2. - Бензин водителю:', gasoline, isExpense: true),
            _buildCalculationStep('3. - Материалы:', materials, isExpense: true),
            _buildCalculationStep('4. - Амортизация 5%:', amortization, isExpense: true),
            
            const Divider(height: 20),
            
            _buildCalculationStep(
              '5. Остаток к распределению:',
              _salaryCalculation!['remaining_before_split'] as double,
              isBold: true,
            ),
            
            _buildCalculationStep(
              '6. На каждого из ${_project.workers.length} чел.:',
              _salaryCalculation!['salary_per_worker_base'] as double,
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            // Итоговые зарплаты
            const Text(
              'Итоговые зарплаты:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            ...salaries.entries.map((entry) {
              final isDriver = entry.key == driverName;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(entry.key),
                        if (isDriver) const SizedBox(width: 8),
                        if (isDriver) const Icon(Icons.directions_car, size: 16, color: Colors.blue),
                      ],
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(2)} ₽',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: entry.value >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            // Итого выплат
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ИТОГО выплат бригаде:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${salaries.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseDetail(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('• $label'),
          Text(
            '${value.toStringAsFixed(2)} ₽',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow({
    required String label,
    required double value,
    bool isHeader = false,
    bool isExpense = false,
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isHeader ? 16 : 14,
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} ₽',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isExpense ? Colors.red : Colors.green),
              fontSize: isHeader ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationStep(String label, double value, {
    bool isExpense = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
          Text(
            '${isExpense ? '-' : ''}${value.toStringAsFixed(2)} ₽',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isExpense ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансовый учёт'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Экспорт в PDF
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFinanceSummary(),
            const SizedBox(height: 16),
            _buildSalaryCalculation(),
            const SizedBox(height: 32),
            
            // Сводка текстом
            if (_salaryCalculation != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Полная сводка',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _salaryCalculation!['summary_text'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
