import 'dart:io';
import 'package:flutter/material.dart';
import '../models/company_profile.dart';
import '../data/database_helper.dart';
import '../services/template_service.dart';
import '../services/backup_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TemplateService _templateService = TemplateService();
  final BackupService _backupService = BackupService();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<FormState> _companyFormKey = GlobalKey<FormState>();

  // Состояние экрана
  int _settingsTabIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _logoPath;
  File? _logoFile;

  // Контроллеры для полей компании
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _companyWebsiteController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();
  final TextEditingController _companyFooterController = TextEditingController();

  // Данные шаблонов
  List<Map<String, dynamic>> _paymentTemplates = [];
  List<Map<String, dynamic>> _workTemplates = [];
  List<Map<String, dynamic>> _installationTemplates = [];
  List<Map<String, dynamic>> _noteTemplates = [];

  // Данные резервного копирования
  List<File> _backupFiles = [];
  Map<String, dynamic> _databaseStats = {};
  bool _isLoadingBackups = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Загрузка всех данных
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Загружаем данные компании
      final company = await _dbHelper.getDefaultCompany();
      if (company != null) {
        _companyNameController.text = company.name;
        _companyPhoneController.text = company.phone ?? '';
        _companyEmailController.text = company.email ?? '';
        _companyWebsiteController.text = company.website ?? '';
        _companyAddressController.text = company.address ?? '';
        _companyFooterController.text = company.footerNote ?? '';
        _logoPath = company.logoPath;
      }

      // Инициализируем и загружаем шаблоны
      await _templateService.initializeTemplates();
      _paymentTemplates = await _templateService.getTemplatesByType(TemplateService.typePayment);
      _workTemplates = await _templateService.getTemplatesByType(TemplateService.typeWork);
      _installationTemplates = await _templateService.getTemplatesByType(TemplateService.typeInstallation);
      _noteTemplates = await _templateService.getTemplatesByType(TemplateService.typeNote);
    } catch (error) {
      developer.log('Ошибка загрузки данных: $error');
      _showErrorSnackbar('Ошибка загрузки данных');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Загрузка данных для вкладки резервного копирования
  Future<void> _loadBackupData() async {
    if (_settingsTabIndex != 2) return;
    
    setState(() => _isLoadingBackups = true);
    try {
      _backupFiles = await _backupService.getBackupFiles();
      _databaseStats = await _backupService.getDatabaseStats();
    } catch (error) {
      developer.log('Ошибка загрузки резервных копий: $error');
    } finally {
      setState(() => _isLoadingBackups = false);
    }
  }

  // Сохранение настроек компании
  Future<void> _saveCompanySettings() async {
    if (_companyFormKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      try {
        final company = CompanyProfile(
          name: _companyNameController.text,
          phone: _companyPhoneController.text.isNotEmpty ? _companyPhoneController.text : null,
          email: _companyEmailController.text.isNotEmpty ? _companyEmailController.text : null,
          website: _companyWebsiteController.text.isNotEmpty ? _companyWebsiteController.text : null,
          address: _companyAddressController.text.isNotEmpty ? _companyAddressController.text : null,
          footerNote: _companyFooterController.text.isNotEmpty ? _companyFooterController.text : null,
          logoPath: _logoPath,
        );

        await _dbHelper.insertCompany(company);
        _showSuccessSnackbar('Настройки компании сохранены');
      } catch (error) {
        developer.log('Ошибка сохранения: $error');
        _showErrorSnackbar('Ошибка сохранения');
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  // Выбор логотипа
  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _logoFile = File(image.path);
          _logoPath = image.path;
        });
      }
    } catch (error) {
      developer.log('Ошибка выбора изображения: $error');
      _showErrorSnackbar('Ошибка выбора изображения');
    }
  }

  // Удаление логотипа
  void _removeLogo() {
    setState(() {
      _logoFile = null;
      _logoPath = null;
    });
  }

  // Вспомогательные методы для уведомлений
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Заголовок секции
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  // Поле ввода для настроек
  Widget _buildCompanyField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Это поле обязательно';
          }
          return null;
        },
      ),
    );
  }

  // ==================== ВКЛАДКА НАСТРОЕК КОМПАНИИ ====================
  Widget _buildCompanySettingsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _companyFormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Логотип компании'),
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _logoFile != null || _logoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _logoFile ?? File(_logoPath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.business,
                          size: 40,
                          color: Colors.grey,
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.photo),
                      label: const Text('Выбрать'),
                    ),
                    const SizedBox(width: 8),
                    if (_logoFile != null || _logoPath != null)
                      ElevatedButton.icon(
                        onPressed: _removeLogo,
                        icon: const Icon(Icons.delete),
                        label: const Text('Удалить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          _buildSectionHeader('Основная информация'),
          _buildCompanyField(
            controller: _companyNameController,
            label: 'Название компании *',
            isRequired: true,
          ),
          _buildCompanyField(
            controller: _companyPhoneController,
            label: 'Телефон',
            hint: '+7 (999) 123-45-67',
            keyboardType: TextInputType.phone,
          ),
          _buildCompanyField(
            controller: _companyEmailController,
            label: 'Email',
            hint: 'info@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          _buildCompanyField(
            controller: _companyWebsiteController,
            label: 'Веб-сайт',
            hint: 'https://example.com',
            keyboardType: TextInputType.url,
          ),
          _buildCompanyField(
            controller: _companyAddressController,
            label: 'Юридический адрес',
            maxLines: 2,
          ),

          _buildSectionHeader('Дополнительно'),
          _buildCompanyField(
            controller: _companyFooterController,
            label: 'Текст для подвала PDF',
            hint: 'Благодарим за выбор нашей компании!',
            maxLines: 3,
          ),

          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveCompanySettings,
            icon: _isSaving
                ? const CircularProgressIndicator()
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Сохранение...' : 'Сохранить настройки'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ВКЛАДКА ШАБЛОНОВ ====================
  Widget _buildTemplatesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Шаблоны условий оплаты
          _buildTemplateSection(
            title: 'Шаблоны условий оплаты',
            templates: _paymentTemplates,
            icon: Icons.payment,
            type: TemplateService.typePayment,
          ),

          // Шаблоны условий монтажа
          _buildTemplateSection(
            title: 'Шаблоны условий монтажа',
            templates: _installationTemplates,
            icon: Icons.build,
            type: TemplateService.typeInstallation,
          ),

          // Шаблоны работ
          _buildTemplateSection(
            title: 'Шаблоны работ',
            templates: _workTemplates,
            icon: Icons.handyman,
            type: TemplateService.typeWork,
          ),

          // Шаблоны примечаний
          _buildTemplateSection(
            title: 'Шаблоны примечаний',
            templates: _noteTemplates,
            icon: Icons.note,
            type: TemplateService.typeNote,
          ),

          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addNewTemplate,
            icon: const Icon(Icons.add),
            label: const Text('Добавить новый шаблон'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Секция шаблонов
  Widget _buildTemplateSection({
    required String title,
    required List<Map<String, dynamic>> templates,
    required IconData icon,
    required String type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        if (templates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Нет шаблонов',
              style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ),
        ...templates.map((template) => _buildTemplateCard(template)),
      ],
    );
  }

  // Карточка шаблона
  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(
            _getTemplateIcon(template['type'] as String),
            color: Colors.blue,
          ),
        ),
        title: Text(
          template['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          (template['content'] as String).length > 60
              ? '${(template['content'] as String).substring(0, 60)}...'
              : template['content'] as String,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleTemplateAction(value, template),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
        ),
        onTap: () => _editTemplate(template),
      ),
    );
  }

  // Получение иконки для типа шаблона
  IconData _getTemplateIcon(String type) {
    switch (type) {
      case TemplateService.typePayment:
        return Icons.payment;
      case TemplateService.typeInstallation:
        return Icons.build;
      case TemplateService.typeWork:
        return Icons.handyman;
      case TemplateService.typeNote:
        return Icons.note;
      default:
        return Icons.description;
    }
  }

  // Обработка действий с шаблоном
  void _handleTemplateAction(String action, Map<String, dynamic> template) {
    switch (action) {
      case 'edit':
        _editTemplate(template);
        break;
      case 'delete':
        _deleteTemplate(template['id'] as int);
        break;
    }
  }

  // Добавление нового шаблона
  Future<void> _addNewTemplate() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddTemplateDialog(),
    );

    if (result != null) {
      try {
        await _templateService.addTemplate(
          type: result['type'] as String,
          title: result['title'] as String,
          content: result['content'] as String,
        );
        _showSuccessSnackbar('Шаблон добавлен');
        await _loadData();
      } catch (error) {
        developer.log('Ошибка добавления шаблона: $error');
        _showErrorSnackbar('Ошибка добавления шаблона');
      }
    }
  }

  // Редактирование шаблона
  Future<void> _editTemplate(Map<String, dynamic> template) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddTemplateDialog(
        initialTitle: template['title'] as String,
        initialContent: template['content'] as String,
        initialType: template['type'] as String,
      ),
    );

    if (result != null) {
      try {
        await _templateService.updateTemplate(
          id: template['id'] as int,
          title: result['title'] as String,
          content: result['content'] as String,
        );
        _showSuccessSnackbar('Шаблон обновлен');
        await _loadData();
      } catch (error) {
        developer.log('Ошибка обновления шаблона: $error');
        _showErrorSnackbar('Ошибка обновления шаблона');
      }
    }
  }

  // Удаление шаблона
  Future<void> _deleteTemplate(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить шаблон?'),
        content: const Text('Шаблон будет удален безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _templateService.deleteTemplate(id);
        _showSuccessSnackbar('Шаблон удален');
        await _loadData();
      } catch (error) {
        developer.log('Ошибка удаления шаблона: $error');
        _showErrorSnackbar('Ошибка удаления шаблона');
      }
    }
  }

  // ==================== ВКЛАДКА РЕЗЕРВНОГО КОПИРОВАНИЯ ====================
  Widget _buildBackupTab() {
    return RefreshIndicator(
      onRefresh: _loadBackupData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Статистика базы данных'),
          _buildDatabaseStats(),

          _buildSectionHeader('Управление резервными копиями'),
          _buildBackupActions(),

          _buildSectionHeader('Список резервных копий'),
          _buildBackupList(),
        ],
      ),
    );
  }

  // Статистика базы данных
  Widget _buildDatabaseStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_databaseStats['error'] != null)
              Text(
                _databaseStats['error'] as String,
                style: const TextStyle(color: Colors.red),
              )
            else ...[
              _buildStatRow('КП в базе:', '${_databaseStats['quotesCount'] ?? 0}'),
              _buildStatRow('Позиций работ:', '${_databaseStats['lineItemsCount'] ?? 0}'),
              _buildStatRow('Шаблонов:', '${_databaseStats['templatesCount'] ?? 0}'),
              if (_databaseStats['databaseSize'] != null)
                _buildStatRow('Размер базы:', _databaseStats['databaseSize'] as String),
              if (_databaseStats['lastBackup'] != null)
                _buildStatRow('Последняя копия:', _databaseStats['lastBackup'] as String),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Кнопки управления резервными копиями
  Widget _buildBackupActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _createBackup,
                icon: const Icon(Icons.save_alt),
                label: const Text('Создать резервную копию'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _restoreBackup,
                icon: const Icon(Icons.restore),
                label: const Text('Восстановить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade50,
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Резервные копии сохраняются в папке загрузок устройства',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Список резервных копий
  Widget _buildBackupList() {
    if (_isLoadingBackups) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_backupFiles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Нет резервных копий. Создайте первую копию, нажав на кнопку выше.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: _backupFiles.map((file) => _buildBackupItem(file)).toList(),
    );
  }

  // Элемент списка резервных копий
  Widget _buildBackupItem(File file) {
    final info = _backupService.getFileInfo(file);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.backup, color: Colors.blue),
        title: Text(info['name'] as String),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Размер: ${info['size']}'),
            Text('Создана: ${info['formattedDate']}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleBackupAction(value, file),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'restore', child: Text('Восстановить')),
            const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
        ),
      ),
    );
  }

  // Обработка действий с резервной копией
  void _handleBackupAction(String action, File file) {
    switch (action) {
      case 'restore':
        _confirmRestore(file);
        break;
      case 'delete':
        _confirmDelete(file);
        break;
    }
  }

  // Создание резервной копии
  Future<void> _createBackup() async {
    try {
      final backupFile = await _backupService.exportDatabase();
      final info = _backupService.getFileInfo(backupFile);
      
      _showSuccessSnackbar('Резервная копия создана: ${info['name']}');
      await _loadBackupData();
    } catch (error) {
      developer.log('Ошибка создания резервной копии: $error');
      _showErrorSnackbar('Ошибка создания резервной копии');
    }
  }

  // Подтверждение восстановления
  Future<void> _confirmRestore(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановить из резервной копии?'),
        content: const Text('Текущие данные будут заменены данными из резервной копии. Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _restoreFromFile(file);
    }
  }

  // Восстановление из файла
  Future<void> _restoreFromFile(File file) async {
    try {
      await _backupService.importDatabase(file);
      _showSuccessSnackbar('База данных успешно восстановлена');
      
      // Перезагружаем все данные
      await _loadData();
      await _loadBackupData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Перезапустите приложение для применения изменений'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (error) {
      developer.log('Ошибка восстановления: $error');
      _showErrorSnackbar('Ошибка восстановления: $error');
    }
  }

  // Подтверждение удаления
  Future<void> _confirmDelete(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить резервную копию?'),
        content: const Text('Резервная копия будет удалена безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBackup(file);
    }
  }

  // Удаление резервной копии
  Future<void> _deleteBackup(File file) async {
    try {
      await _backupService.deleteBackup(file);
      _showSuccessSnackbar('Резервная копия удалена');
      await _loadBackupData();
    } catch (error) {
      developer.log('Ошибка удаления: $error');
      _showErrorSnackbar('Ошибка удаления');
    }
  }

  // Общий вызов восстановления
  Future<void> _restoreBackup() async {
    if (_backupFiles.isEmpty) {
      _showInfoSnackbar('Сначала создайте резервную копию');
      return;
    }

    _confirmRestore(_backupFiles.first);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Настройки'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.business), text: 'Компания'),
              Tab(icon: Icon(Icons.format_quote), text: 'Шаблоны'),
              Tab(icon: Icon(Icons.backup), text: 'Резервные копии'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCompanySettingsTab(),
            _buildTemplatesTab(),
            _buildBackupTab(),
          ],
        ),
      ),
    );
  }
}

// Диалог добавления/редактирования шаблона
class _AddTemplateDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final String? initialType;

  const _AddTemplateDialog({
    this.initialTitle,
    this.initialContent,
    this.initialType,
  });

  @override
  _AddTemplateDialogState createState() => _AddTemplateDialogState();
}

class _AddTemplateDialogState extends State<_AddTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedType = TemplateService.typePayment;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _contentController.text = widget.initialContent ?? '';
    _selectedType = widget.initialType ?? TemplateService.typePayment;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTitle == null ? 'Новый шаблон' : 'Редактирование шаблона'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Тип шаблона',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: TemplateService.typePayment,
                  child: const Text('Условия оплаты'),
                ),
                DropdownMenuItem(
                  value: TemplateService.typeInstallation,
                  child: const Text('Условия монтажа'),
                ),
                DropdownMenuItem(
                  value: TemplateService.typeWork,
                  child: const Text('Работы'),
                ),
                DropdownMenuItem(
                  value: TemplateService.typeNote,
                  child: const Text('Примечания'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Содержание',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите содержание';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'type': _selectedType,
                'title': _titleController.text,
                'content': _contentController.text,
              });
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
