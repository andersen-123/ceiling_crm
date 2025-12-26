// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Контроллеры для полей
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();
  final TextEditingController _companyInnController = TextEditingController();
  final TextEditingController _managerNameController = TextEditingController();
  
  // Логотип компании
  File? _companyLogo;
  final ImagePicker _picker = ImagePicker();
  
  // Состояние загрузки
  bool _isLoading = true;
  bool _isSaving = false;

  // Ключи для SharedPreferences
  static const String _keyCompanyName = 'company_name';
  static const String _keyCompanyPhone = 'company_phone';
  static const String _keyCompanyEmail = 'company_email';
  static const String _keyCompanyAddress = 'company_address';
  static const String _keyCompanyInn = 'company_inn';
  static const String _keyManagerName = 'manager_name';
  static const String _keyLogoPath = 'logo_path';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Загрузка настроек
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _companyNameController.text = prefs.getString(_keyCompanyName) ?? '';
      _companyPhoneController.text = prefs.getString(_keyCompanyPhone) ?? '';
      _companyEmailController.text = prefs.getString(_keyCompanyEmail) ?? '';
      _companyAddressController.text = prefs.getString(_keyCompanyAddress) ?? '';
      _companyInnController.text = prefs.getString(_keyCompanyInn) ?? '';
      _managerNameController.text = prefs.getString(_keyManagerName) ?? '';
      
      final logoPath = prefs.getString(_keyLogoPath);
      if (logoPath != null && File(logoPath).existsSync()) {
        setState(() => _companyLogo = File(logoPath));
      }
      
    } catch (e) {
      debugPrint('Ошибка загрузки настроек: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Сохранение настроек
  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_keyCompanyName, _companyNameController.text);
      await prefs.setString(_keyCompanyPhone, _companyPhoneController.text);
      await prefs.setString(_keyCompanyEmail, _companyEmailController.text);
      await prefs.setString(_keyCompanyAddress, _companyAddressController.text);
      await prefs.setString(_keyCompanyInn, _companyInnController.text);
      await prefs.setString(_keyManagerName, _managerNameController.text);
      
      if (_companyLogo != null) {
        await prefs.setString(_keyLogoPath, _companyLogo!.path);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Выбор логотипа
  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() => _companyLogo = File(image.path));
    }
  }

  // Удаление логотипа
  void _removeLogo() {
    setState(() => _companyLogo = null);
  }

  // Сброс настроек
  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс настроек'),
        content: const Text('Все настройки компании будут сброшены к значениям по умолчанию. Продолжить?'),
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _loadSettings(); // Перезагружаем (пустые) настройки
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сброшены')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки компании'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveSettings,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Логотип компании
          _buildLogoSection(),
          const SizedBox(height: 24),
          
          // Основная информация
          _buildCompanyInfoSection(),
          const SizedBox(height: 24),
          
          // Контактная информация
          _buildContactInfoSection(),
          const SizedBox(height: 24),
          
          // Дополнительные настройки
          _buildAdditionalSettings(),
          const SizedBox(height: 32),
          
          // Кнопки управления
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Логотип компании',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _pickLogo,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: _companyLogo == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Добавить логотип',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_companyLogo!, fit: BoxFit.cover),
                    ),
            ),
          ),
        ),
        if (_companyLogo != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _removeLogo,
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Удалить логотип'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompanyInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Основная информация',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _companyNameController,
          decoration: const InputDecoration(
            labelText: 'Название компании *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _companyInnController,
          decoration: const InputDecoration(
            labelText: 'ИНН',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _managerNameController,
          decoration: const InputDecoration(
            labelText: 'Имя менеджера',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Контактная информация',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _companyPhoneController,
          decoration: const InputDecoration(
            labelText: 'Телефон',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _companyEmailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _companyAddressController,
          decoration: const InputDecoration(
            labelText: 'Адрес',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildAdditionalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дополнительные настройки',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Автосохранение черновиков'),
          subtitle: const Text('Автоматически сохранять изменения каждые 5 минут'),
          value: true,
          onChanged: (value) {},
        ),
        SwitchListTile(
          title: const Text('Уведомления о новых заказах'),
          subtitle: const Text('Получать push-уведомления'),
          value: false,
          onChanged: (value) {},
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Язык интерфейса'),
          subtitle: const Text('Русский'),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Сохранить все настройки'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetSettings,
                icon: const Icon(Icons.restart_alt, size: 20),
                label: const Text('Сбросить настройки'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.help_outline, size: 20),
                label: const Text('Помощь'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Ceiling CRM v1.0.0',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _companyAddressController.dispose();
    _companyInnController.dispose();
    _managerNameController.dispose();
    super.dispose();
  }
}
