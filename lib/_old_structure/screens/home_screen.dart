import 'package:flutter/material.dart';
import 'package:ceiling_crm/screens/project_detail_screen.dart';
import 'package:ceiling_crm/screens/project_create_screen.dart';
import 'package:ceiling_crm/database/database_helper.dart';
import 'package:ceiling_crm/models/project.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final projects = await _dbHelper.getAllProjects();
      setState(() => _projects = projects);
    } catch (e) {
      print('Ошибка загрузки проектов: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToCreateProject() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectCreateScreen(
          onProjectCreated: _loadProjects,
        ),
      ),
    );
  }

  void _navigateToProjectDetail(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(project: project),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final statusColors = {
      'plan': Colors.blue,
      'active': Colors.green,
      'completed': Colors.grey,
      'paid': Colors.purple,
    };

    final statusNames = {
      'plan': 'Планирование',
      'active': 'В работе',
      'completed': 'Завершён',
      'paid': 'Оплачен',
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColors[project.status] ?? Colors.grey,
          child: Text(
            project.title.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          project.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              statusNames[project.status] ?? project.status,
              style: TextStyle(
                color: statusColors[project.status] ?? Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Договор: ${project.contractSum.toStringAsFixed(2)} ₽',
              style: const TextStyle(fontSize: 14),
            ),
            if (project.workers.isNotEmpty)
              Text(
                'Бригада: ${project.workers.length} чел.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${project.balance.toStringAsFixed(2)} ₽',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: project.balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Остаток',
              style: TextStyle(
                fontSize: 10,
                color: project.balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToProjectDetail(project),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет проектов',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Создайте первый проект для учёта',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ceiling CRM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjects,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadProjects,
                  child: ListView.builder(
                    itemCount: _projects.length,
                    itemBuilder: (context, index) =>
                        _buildProjectCard(_projects[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateProject,
        icon: const Icon(Icons.add),
        label: const Text('Новый проект'),
      ),
    );
  }
}
