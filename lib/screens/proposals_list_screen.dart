// lib/screens/proposals_list_screen.dart
import 'package:flutter/material.dart';
import 'package:ceiling_crm/services/database_helper.dart';
import 'package:ceiling_crm/screens/proposal_detail_screen.dart';
import 'package:ceiling_crm/screens/create_proposal_screen.dart';

class ProposalsListScreen extends StatefulWidget {
  const ProposalsListScreen({super.key});

  @override
  State<ProposalsListScreen> createState() => _ProposalsListScreenState();
}

class _ProposalsListScreenState extends State<ProposalsListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _proposals = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProposals();
  }

  Future<void> _loadProposals() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final proposals = await _dbHelper.getAllProposals();
      setState(() {
        _proposals = proposals;
      });
    } catch (e) {
      print('Ошибка загрузки КП: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProposals {
    if (_searchQuery.isEmpty) return _proposals;
    
    return _proposals.where((proposal) {
      final clientName = proposal['clientName']?.toString().toLowerCase() ?? '';
      final address = proposal['address']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return clientName.contains(query) || address.contains(query);
    }).toList();
  }

  Future<void> _deleteProposal(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить КП?'),
        content: const Text('Вы уверены, что хотите удалить это коммерческое предложение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteProposal(id);
      await _loadProposals();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('КП удалено'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProposalCard(Map<String, dynamic> proposal) {
    final createdAt = proposal['createdAt'] != null
        ? DateTime.parse(proposal['createdAt'])
        : DateTime.now();
    final dateStr = '${createdAt.day}.${createdAt.month}.${createdAt.year}';
    final total = proposal['totalAmount'] ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProposalDetailScreen(
                proposal: proposal,
              ),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(
            Icons.description,
            color: Colors.blue.shade700,
          ),
        ),
        title: Text(
          proposal['clientName'] ?? 'Без названия',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(proposal['address'] ?? 'Адрес не указан'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const Spacer(),
                Text(
                  '${total.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteProposal(proposal['id']);
            } else if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateProposalScreen(
                    proposalToEdit: proposal,
                  ),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Редактировать'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Удалить', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет коммерческих предложений',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Создайте первое КП для вашего клиента',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateProposalScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Создать КП'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Коммерческие предложения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProposals,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Поиск по клиентам или адресам...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          
          // Статистика
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  backgroundColor: Colors.blue.shade50,
                  label: Text(
                    'Всего: ${_proposals.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  backgroundColor: Colors.green.shade50,
                  label: Text(
                    'Сумма: ${_calculateTotalSum().toStringAsFixed(2)} ₽',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Список
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProposals.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProposals,
                        child: ListView.builder(
                          itemCount: _filteredProposals.length,
                          itemBuilder: (context, index) {
                            return _buildProposalCard(_filteredProposals[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateProposalScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  double _calculateTotalSum() {
    return _proposals.fold(0.0, (sum, proposal) {
      return sum + (proposal['totalAmount'] ?? 0.0);
    });
  }
}
