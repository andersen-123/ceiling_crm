import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/company_profile.dart';
import 'package:ceiling_crm/services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _companyNameController;
  late TextEditingController _managerNameController;
  late TextEditingController _positionController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _vatController;
  late TextEditingController _marginController;
  late TextEditingController _currencyController;

  CompanyProfile? _companyProfile;

  @override
  void initState() {
    super.initState();
    
    _companyNameController = TextEditingController();
    _managerNameController = TextEditingController();
    _positionController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _websiteController = TextEditingController();
    _vatController = TextEditingController();
    _marginController = TextEditingController();
    _currencyController = TextEditingController();
    
    _loadCompanyProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _managerNameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _vatController.dispose();
    _marginController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyProfile() async {
    try {
      final profile = await _dbHelper.getCompanyProfile();
      setState(() {
        _companyProfile = profile;
      });
      
      if (_companyProfile != null) {
        _companyNameController.text = _companyProfile!.companyName;
        _managerNameController.text = _companyProfile!.managerName;
        _positionController.text = _companyProfile!.position;
        _phoneController.text = _companyProfile!.phone ?? '';
        _emailController.text = _companyProfile!.email ?? '';
        _addressController.text = _companyProfile!.address ?? '';
        _websiteController.text = _companyProfile!.website ?? '';
        _vatController.text = _companyProfile!.vatRate.toString();
        _marginController.text = _companyProfile!.defaultMargin.toString();
        _currencyController.text = _companyProfile!.currency;
      } else {
        // Если профиля нет, создаем пустой
        _companyProfile = CompanyProfile.defaultProfile();
        _companyNameController.text = _companyProfile!.companyName;
        _managerNameController.text = _companyProfile!.managerName;
        _positionController.text = _companyProfile!.position;
        _phoneController.text = _companyProfile!.phone ?? '';
        _emailController.text = _companyProfile!.email ?? '';
        _addressController.text = _companyProfile!.address ?? '';
        _websiteController.text = _companyProfile!.website ?? '';
        _vatController.text = _companyProfile!.vatRate.toString();
        _marginController.text = _companyProfile!.defaultMargin.toString();
        _currencyController.text = _companyProfile!.currency;
      }
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
      // Создаем профиль по умолчанию при ошибке
      _companyProfile = CompanyProfile.defaultProfile();
      _companyNameController.text = _companyProfile!.companyName;
      _managerNameController.text = _companyProfile!.managerName;
      _positionController.text = _companyProfile!.position;
      _phoneController.text = _companyProfile!.phone ?? '';
      _emailController.text = _companyProfile!.email ?? '';
      _addressController.text = _companyProfile!.address ?? '';
    }
  }

  Future<void> _saveCompanyProfile() async {
    if (_formKey.currentState!.validate()) {
      final newProfile = CompanyProfile(
        id: _companyProfile?.id,
        companyName: _companyNameController.text.trim(),
        managerName: _managerNameController.text.trim(),
        position: _positionController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
        vatRate: double.tryParse(_vatController.text) ?? 0.0,
        defaultMargin: double.tryParse(_marginController.text) ?? 0.0,
        currency: _currencyController.text.trim(),
      );

      try {
        if (_companyProfile?.id != null) {
          await _dbHelper.updateCompanyProfile(newProfile);
        } else {
          await _dbHelper.insertCompanyProfile(newProfile);
        }
        
        setState(() {
          _companyProfile = newProfile;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль компании сохранен')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  void _resetToDefaults() {
    setState(() {
      _companyProfile = CompanyProfile.defaultProfile();
      _companyNameController.text = _companyProfile!.companyName;
      _managerNameController.text = _companyProfile!.managerName;
      _positionController.text = _companyProfile!.position;
      _phoneController.text = _companyProfile!.phone ?? '';
      _emailController.text = _companyProfile!.email ?? '';
      _addressController.text = _companyProfile!.address ?? '';
      _websiteController.text = _companyProfile!.website ?? '';
      _vatController.text = _companyProfile!.vatRate.toString();
      _marginController.text = _companyProfile!.defaultMargin.toString();
      _currencyController.text = _companyProfile!.currency;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки компании'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCompanyProfile,
          ),
        ],
      ),
      body: _companyProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader('Информация о компании'),
                    _buildTextField(
                      controller: _companyNameController,
                      label: 'Название компании',
                      icon: Icons.business,
                      required: true,
                    ),
                    _buildTextField(
                      controller: _managerNameController,
                      label: 'Имя менеджера',
                      icon: Icons.person,
                    ),
                    _buildTextField(
                      controller: _positionController,
                      label: 'Должность',
                      icon: Icons.work,
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Телефон',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Адрес',
                      icon: Icons.location_on,
                    ),
                    _buildTextField(
                      controller: _websiteController,
                      label: 'Веб-сайт',
                      icon: Icons.language,
                      keyboardType: TextInputType.url,
                    ),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader('Финансовые настройки'),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _vatController,
                            label: 'НДС, %',
                            icon: Icons.percent,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _marginController,
                            label: 'Наценка, %',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    
                    _buildTextField(
                      controller: _currencyController,
                      label: 'Валюта',
                      icon: Icons.money,
                    ),
                    
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveCompanyProfile,
                            icon: const Icon(Icons.save),
                            label: const Text('Сохранить'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _resetToDefaults,
                          icon: const Icon(Icons.restore),
                          label: const Text('По умолчанию'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Это поле обязательно для заполнения';
          }
          return null;
        },
      ),
    );
  }
}
