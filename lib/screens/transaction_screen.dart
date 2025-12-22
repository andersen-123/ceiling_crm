import 'package:flutter/material.dart';
import 'package:ceiling_crm/database/database_helper.dart';
import 'package:ceiling_crm/models/transaction.dart';

class TransactionScreen extends StatefulWidget {
  final int projectId;
  final VoidCallback onTransactionAdded;

  const TransactionScreen({
    super.key,
    required this.projectId,
    required this.onTransactionAdded,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      _transactions = await _dbHelper.getProjectTransactions(widget.projectId);
    } catch (e) {
      print('Ошибка загрузки транзакций: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        projectId: widget.projectId,
        onTransactionAdded: () {
          _loadTransactions();
          widget.onTransactionAdded();
        },
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Нет операций',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Добавьте первую операцию',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Группируем по дате
    final Map<String, List<Transaction>> groupedByDate = {};
    for (final transaction in _transactions) {
      final date = transaction.date.toString().substring(0, 10);
      groupedByDate.putIfAbsent(date, () => []).add(transaction);
    }

    return ListView(
      children: [
        ...groupedByDate.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ),
              ...entry.value.map((transaction) => _buildTransactionCard(transaction)),
              const Divider(height: 1),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: transaction.isIncome ? Colors.green[50] : Colors.red[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isIncome ? Colors.green : Colors.red,
          child: Icon(
            transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: Colors.white,
          ),
        ),
        title: Text(
          transaction.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (transaction.comment != null && transaction.comment!.isNotEmpty)
              Text(
                transaction.comment!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Text(
              transaction.date.toString().substring(11, 16),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction.amount.toStringAsFixed(2)} ₽',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transaction.isIncome ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                transaction.isIncome ? 'Доход' : 'Расход',
                style: TextStyle(
                  fontSize: 10,
                  color: transaction.isIncome ? Colors.green : Colors.red,
                ),
              ),
              backgroundColor: transaction.isIncome
                  ? Colors.green[100]
                  : Colors.red[100],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Операции по проекту'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTransactionList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Добавить операцию'),
      ),
    );
  }
}

// Диалог добавления транзакции
class AddTransactionDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback onTransactionAdded;

  const AddTransactionDialog({
    super.key,
    required this.projectId,
    required this.onTransactionAdded,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  // Контроллеры
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  
  // Поля формы
  String _transactionType = 'expense';
  String _category = 'Бензин';
  DateTime _date = DateTime.now();
  
  // Категории для расходов (как в вашем примере)
  static const List<String> expenseCategories = [
    'Бензин',
    'Полотна москва',
    'Все полотна',
    'Леруа',
    'Диски',
    'Комплект потолок',
    'Комплект карниза',
    'Световое оборудование',
    'Прочие расходы',
  ];
  
  // Категории для доходов
  static const List<String> incomeCategories = [
    'Аванс',
    'Оплата по договору',
    'Дополнительные работы',
    'Прочие доходы',
  ];

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final transaction = Transaction(
        projectId: widget.projectId,
        type: _transactionType,
        category: _category,
        amount: double.parse(_amountController.text),
        comment: _commentController.text.isNotEmpty ? _commentController.text : null,
        date: _date,
      );

      await _dbHelper.insertTransaction(transaction);
      widget.onTransactionAdded();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Операция успешно добавлена'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCategories = _transactionType == 'income'
        ? incomeCategories
        : expenseCategories;

    return AlertDialog(
      title: const Text('Добавить операцию'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Тип операции
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'expense',
                    label: Text('Расход'),
                    icon: Icon(Icons.arrow_upward, color: Colors.red),
                  ),
                  ButtonSegment<String>(
                    value: 'income',
                    label: Text('Доход'),
                    icon: Icon(Icons.arrow_downward, color: Colors.green),
                  ),
                ],
                selected: {_transactionType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _transactionType = newSelection.first;
                    // Сбрасываем категорию на первую доступную
                    _category = currentCategories.first;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Категория
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                ),
                items: currentCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _category = value!);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите категорию';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Сумма
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  suffixText: '₽',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите сумму';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Введите число';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Дата
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Дата операции',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_date.toString().substring(0, 10)),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Комментарий
              TextFormField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveTransaction,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
