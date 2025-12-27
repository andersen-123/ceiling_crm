// lib/screens/proposal_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:ceiling_crm/screens/edit_position_modal.dart';
import 'package:ceiling_crm/screens/pdf_preview_screen.dart';
import 'package:ceiling_crm/services/database_helper.dart';

class ProposalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> proposal;

  const ProposalDetailScreen({
    super.key,
    required this.proposal,
  });

  @override
  State<ProposalDetailScreen> createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends State<ProposalDetailScreen> {
  late Map<String, dynamic> _proposal;
  bool _isLoading = false;
  bool _isSaving = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _proposal = Map<String, dynamic>.from(widget.proposal);
    // Инициализируем позиции, если их нет
    _proposal['positions'] ??= [];
  }

  // Рассчитываем общую сумму
  double _calculateTotal() {
    double total = 0;
    for (var position in _proposal['positions']) {
      final quantity = position['quantity'] ?? 0;
      final price = position['price'] ?? 0;
      total += quantity * price;
    }
    return total;
  }

  // Сохранение КП в БД
  Future<void> _saveProposal() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Обновляем общую сумму
      _proposal['totalAmount'] = _calculateTotal();
      _proposal['updatedAt'] = DateTime.now().toIso8601String();

      // Сохраняем в базу данных
      await _dbHelper.updateProposal(_proposal);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('КП сохранено'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Добавление новой позиции
  void _addNewPosition() {
    final newPosition = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': 'Новая позиция',
      'unit': 'шт.',
      'quantity': 1.0,
      'price': 0.0,
      'total': 0.0,
      'description': '',
    };

    setState(() {
      _proposal['positions'].add(newPosition);
    });

    // Открываем редактирование новой позиции
    _editPosition(_proposal['positions'].length - 1);
  }

  // Редактирование позиции
  void _editPosition(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPositionModal(
        position: _proposal['positions'][index],
        onSave: (updatedPosition) {
          setState(() {
            _proposal['positions'][index] = updatedPosition;
          });
          _saveProposal();
        },
      ),
    ).then((value) {
      if (value != null && value['delete'] == true) {
        _deletePosition(index);
      }
    });
  }

  // Удаление позиции
  void _deletePosition(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить позицию?'),
        content: const Text('Вы уверены, что хотите удалить эту позицию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _proposal['positions'].removeAt(index);
              });
              Navigator.pop(context);
              _saveProposal();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // Генерация PDF
  Future<void> _generatePdf() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Сохраняем перед генерацией PDF
      await _saveProposal();
      
      // Переход на экран предпросмотра PDF
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            proposalId: _proposal['id'].toString(),
            clientName: _proposal['clientName'],
            totalAmount: _calculateTotal(),
            proposalData: _proposal,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка генерации PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Быстрое добавление стандартных позиций
  void _addStandardPosition(String name, String unit, double price) {
    final newPosition = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': name,
      'unit': unit,
      'quantity': 1.0,
      'price': price,
      'total': price,
      'description': '',
    };

    setState(() {
      _proposal['positions'].add(newPosition);
    });
    _saveProposal();
  }

  // Строим AppBar с информацией о сумме
  PreferredSizeWidget _buildAppBar() {
    final total = _calculateTotal();
    
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _proposal['clientName'] ?? 'Без названия',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            '${total.toStringAsFixed(2)} ₽',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      actions: [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          onPressed: _isLoading ? null : _generatePdf,
          tooltip: 'Создать PDF',
        ),
      ],
    );
  }

  // Виджет информации о клиенте
  Widget _buildClientInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _proposal['clientName'] ?? 'Клиент не указан',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _proposal['address'] ?? 'Адрес не указан',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  _proposal['phone'] ?? 'Телефон не указан',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Виджет быстрого добавления позиций
  Widget _buildQuickAddPanel() {
    const standardPositions = [
      {'name': 'Полотно MSD Premium', 'unit': 'м²', 'price': 650.0},
      {'name': 'Профиль гарпунный', 'unit': 'м.п.', 'price': 310.0},
      {'name': 'Вставка гарпунная', 'unit': 'м.п.', 'price': 220.0},
      {'name': 'Монтаж светильника', 'unit': 'шт.', 'price': 780.0},
      {'name': 'Монтаж люстры', 'unit': 'шт.', 'price': 1100.0},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'Быстрое добавление',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: standardPositions.map((pos) {
                return ActionChip(
                  label: Text('${pos['name']}\n${pos['price']} ₽'),
                  onPressed: () => _addStandardPosition(
                    pos['name'] as String,
                    pos['unit'] as String,
                    pos['price'] as double,
                  ),
                  backgroundColor: Colors.blue.shade50,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Строим список позиций
  Widget _buildPositionsList() {
    if (_proposal['positions'].isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Позиции не добавлены',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addNewPosition,
              icon: const Icon(Icons.add),
              label: const Text('Добавить первую позицию'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _proposal['positions'].length,
      itemBuilder: (context, index) {
        final position = _proposal['positions'][index];
        final quantity = position['quantity'] ?? 0;
        final price = position['price'] ?? 0;
        final total = quantity * price;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            onTap: () => _editPosition(index),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                (index + 1).toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            title: Text(
              position['name'] ?? 'Без названия',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${quantity} ${position['unit']} × ${price} ₽',
                  style: const TextStyle(fontSize: 12),
                ),
                if (position['description']?.isNotEmpty == true)
                  Text(
                    position['description'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${total.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  position['unit'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Нижняя панель с итогами и кнопками
  Widget _buildBottomPanel() {
    final total = _calculateTotal();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Итого:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)} ₽',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addNewPosition,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить позицию'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveProposal,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Сохранение...' : 'Сохранить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildClientInfo(),
                  const SizedBox(height: 16),
                  _buildQuickAddPanel(),
                  const SizedBox(height: 16),
                  Text(
                    'Позиции сметы (${_proposal['positions'].length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPositionsList(),
                ],
              ),
            ),
          ),
          _buildBottomPanel(),
        ],
      ),
    );
  }
}
