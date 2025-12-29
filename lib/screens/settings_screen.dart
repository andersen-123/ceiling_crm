// ИСПРАВЛЕННЫЕ ИМПОРТЫ:
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ceiling_crm/data/database_helper.dart';  // ИЗМЕНЕНО: из services в data
import 'package:ceiling_crm/models/company_profile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late CompanyProfile _companyProfile;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _taxIdController;
  String? _logoPath;
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _websiteController = TextEditingController();
    _taxIdController = TextEditingController();
  }

  Future<void> _loadCompanyProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _dbHelper.getCompanyProfile();
      if (profile != null) {
        _companyProfile = profile;
        _logoPath = profile.logoPath;
        _updateControllers();
      } else {
        _companyProfile = CompanyProfile(
          id: 1,
          name: 'Ваша компания',
          email: '',
          phone: '',
          address: '',
          website: '',
          taxId: '',
          logoPath: '',
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
      _companyProfile = CompanyProfile(
        id: 1,
        name: 'Ваша компания',
        email: '',
        phone: '',
        address: '',
        website: '',
        taxId: '',
        logoPath: '',
        createdAt: DateTime.now(),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _updateControllers() {
    _nameController.text = _companyProfile.name;
    _emailController.text = _companyProfile.email;
    _phoneController.text = _companyProfile.phone;
    _addressController.text = _companyProfile.address;
    _websiteController.text = _companyProfile.website;
    _taxIdController.text = _companyProfile.taxId;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _logoPath = pickedFile.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Создаем новый объект CompanyProfile с обновленными данными
      _companyProfile = CompanyProfile(
        id: _companyProfile.id,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        website: _websiteController.text,
        taxId: _taxIdController.text,
        logoPath: _logoPath ?? '',
        createdAt: _companyProfile.createdAt,
      );

      await _dbHelper.saveCompanyProfile(_companyProfile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки компании сохранены'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportDatabase() async {
    try {
      final dbFile = await _dbHelper.exportDatabase();
      
      if (await dbFile.exists()) {
        final bytes = await dbFile.readAsBytes();
        final fileName = 'ceiling_crm_backup_${DateTime.now().millisecondsSinceEpoch}.db';
        
        // Для Android 10+ используем file_saver или share_plus
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('База данных сохранена: ${dbFile.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось найти файл базы данных'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка экспорта: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _importDatabase() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      try {
        await _dbHelper.importDatabase(File(pickedFile.path));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('База данных успешно импортирована'),
            duration: Duration(seconds: 3),
          ),
        );
        
        // Перезагружаем профиль после импорта
        await _loadCompanyProfile();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка импорта: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить настройки?'),
        content: const Text('Все настройки компании будут сброшены к значениям по умолчанию.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сбросить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final defaultProfile = CompanyProfile(
        id: 1,
        name: 'Моя компания',
        email: 'info@company.com',
        phone: '+7 (999) 123-45-67',
        address: 'г. Москва, ул. Примерная, д. 1',
        website: 'www.company.com',
        taxId: '1234567890',
        logoPath: '',
        createdAt: DateTime.now(),
      );

      _companyProfile = defaultProfile;
      _updateControllers();
      await _dbHelper.saveCompanyProfile(defaultProfile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки сброшены к значениям по умолчанию'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Логотип компании',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _logoPath != null && _logoPath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_logoPath!),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Добавить\nлоготип',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _logoPath != null && _logoPath!.isNotEmpty
              ? path.basename(_logoPath!)
              : 'Логотип не выбран',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Поле обязательно для заполнения';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildBackupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Резервное копирование',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Создайте резервную копию всех данных приложения для восстановления в случае проблем.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportDatabase,
                    icon: const Icon(Icons.backup),
                    label: const Text('Экспорт данных'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importDatabase,
                    icon: const Icon(Icons.restore),
                    label: const Text('Импорт данных'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'О приложении',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Версия'),
              subtitle: const Text('1.0.0'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('Дата сборки'),
              subtitle: Text(DateTime.now().toString()),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Лицензия'),
              subtitle: const Text('MIT License'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Сообщить об ошибке'),
              onTap: () async {
                const url = 'https://github.com/andersen-123/ceiling_crm/issues';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              },
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
        title: const Text('Настройки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: 'Сохранить настройки',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Настройки компании',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Заполните информацию о вашей компании для использования в КП',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    
                    // Логотип
                    _buildLogoSection(),
                    const SizedBox(height: 32),
                    
                    // Основные поля
                    _buildTextField(
                      label: 'Название компании *',
                      controller: _nameController,
                      hintText: 'ООО "Ваша компания"',
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      hintText: 'info@company.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      label: 'Телефон',
                      controller: _phoneController,
                      hintText: '+7 (999) 123-45-67',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      label: 'Адрес',
                      controller: _addressController,
                      hintText: 'г. Москва, ул. Примерная, д. 1',
                      keyboardType: TextInputType.streetAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      label: 'Веб-сайт',
                      controller: _websiteController,
                      hintText: 'www.company.com',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      label: 'ИНН',
                      controller: _taxIdController,
                      hintText: '1234567890',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    
                    // Кнопки действий
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save),
                            label: const Text('Сохранить настройки'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetToDefaults,
                            icon: const Icon(Icons.restore),
                            label: const Text('Сбросить'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Резервное копирование
                    _buildBackupSection(),
                    const SizedBox(height: 24),
                    
                    // Информация о приложении
                    _buildAppInfoSection(),
                    const SizedBox(height: 32),
                    
                    // Ссылка на GitHub
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          const url = 'https://github.com/andersen-123/ceiling_crm';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        },
                        icon: const Icon(Icons.code),
                        label: const Text('Исходный код на GitHub'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
