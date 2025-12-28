import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ceiling_crm/models/company_profile.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late CompanyProfile _companyProfile;
  bool _isLoading = true;
  
  // Контроллеры
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _vatController;
  late TextEditingController _marginController;
  late TextEditingController _currencyController;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadSettings();
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _websiteController = TextEditingController();
    _vatController = TextEditingController();
    _marginController = TextEditingController();
    _currencyController = TextEditingController();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Загружаем настройки или используем значения по умолчанию
      _companyProfile = CompanyProfile.fromMap({
        'name': prefs.getString('company_name'),
        'phone': prefs.getString('company_phone'),
        'email': prefs.getString('company_email'),
        'address': prefs.getString('company_address'),
        'website': prefs.getString('company_website'),
        'vat_rate': prefs.getDouble('vat_rate'),
        'default_margin': prefs.getDouble('default_margin'),
        'currency': prefs.getString('company_currency'),
      });
      
      // Заполняем контроллеры
      _nameController.text = _companyProfile.name;
      _phoneController.text = _companyProfile.phone;
      _emailController.text = _companyProfile.email;
      _addressController.text = _companyProfile.address;
      _websiteController.text = _companyProfile.website ?? '';
      _vatController.text = _companyProfile.vatRate.toString();
      _marginController.text = _companyProfile.defaultMargin.toString();
      _currencyController.text = _companyProfile.currency;
      
    } catch (e) {
      print('Ошибка загрузки настроек: $e');
      // Используем профиль по умолчанию
      _companyProfile = CompanyProfile.defaultProfile;
      _updateControllersFromProfile();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateControllersFromProfile() {
    _nameController.text = _companyProfile.name;
    _phoneController.text = _companyProfile.phone;
    _emailController.text = _companyProfile.email;
    _addressController.text = _companyProfile.address;
    _websiteController.text = _companyProfile.website ?? '';
    _vatController.text = _companyProfile.vatRate.toString();
    _marginController.text = _companyProfile.defaultMargin.toString();
    _currencyController.text = _companyProfile.currency;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Создаем обновленный профиль
      final updatedProfile = CompanyProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        website: _websiteController.text.trim().isNotEmpty 
            ? _websiteController.text.trim() 
            : null,
        vatRate: double.parse(_vatController.text),
        defaultMargin: double.parse(_marginController.text),
        currency: _currencyController.text.trim(),
      );
      
      // Сохраняем в SharedPreferences
      await prefs.setString('company_name', updatedProfile.name);
      await prefs.setString('company_phone', updatedProfile.phone);
      await prefs.setString('company_email', updatedProfile.email);
      await prefs.setString('company_address', updatedProfile.address);
      if (updatedProfile.website != null) {
        await prefs.setString('company_website', updatedProfile.website!);
      } else {
        await prefs.remove('company_website');
      }
      await prefs.setDouble('vat_rate', updatedProfile.vatRate);
      await prefs.setDouble('default_margin', updatedProfile.defaultMargin);
      await prefs.setString('company_currency', updatedProfile.currency);
      
      // Обновляем текущий профиль
      setState(() {
        _companyProfile = updatedProfile;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Настройки успешно сохранены'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      print('Ошибка сохранения настроек: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Сбросить настройки?'),
        content: Text('Все настройки будут сброшены к значениям по умолчанию. Продолжить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Сбросить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      setState(() {
        _companyProfile = CompanyProfile.defaultProfile;
        _updateControllersFromProfile();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Настройки сброшены к значениям по умолчанию'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _exportSettings() async {
    // В будущем можно добавить экспорт настроек в файл
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Экспорт настроек будет реализован в следующей версии'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Загрузка настроек...'),
          backgroundColor: Colors.blueGrey[800],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки компании'),
        backgroundColor: Colors.blueGrey[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Сохранить настройки',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информация о компании
              _buildSection(
                title: 'Информация о компании',
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Название компании *',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите название компании';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Телефон *',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите телефон компании';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите email компании';
                      }
                      if (!value.contains('@')) {
                        return 'Введите корректный email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Адрес *',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите адрес компании';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _websiteController,
                    decoration: InputDecoration(
                      labelText: 'Веб-сайт',
                      prefixIcon: Icon(Icons.public),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),

              // Настройки расчетов
              _buildSection(
                title: 'Настройки расчетов',
                children: [
                  TextFormField(
                    controller: _vatController,
                    decoration: InputDecoration(
                      labelText: 'Ставка НДС (%) *',
                      prefixIcon: Icon(Icons.percent),
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите ставку НДС';
                      }
                      final val = double.tryParse(value);
                      if (val == null || val < 0 || val > 100) {
                        return 'Введите значение от 0 до 100';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _marginController,
                    decoration: InputDecoration(
                      labelText: 'Наценка по умолчанию (%) *',
                      prefixIcon: Icon(Icons.trending_up),
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите наценку по умолчанию';
                      }
                      final val = double.tryParse(value);
                      if (val == null || val < 0 || val > 500) {
                        return 'Введите значение от 0 до 500';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _currencyController,
                    decoration: InputDecoration(
                      labelText: 'Валюта *',
                      prefixIcon: Icon(Icons.currency_ruble),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите символ валюты';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              // Кнопки действий
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveSettings,
                          icon: Icon(Icons.save),
                          label: Text('Сохранить все настройки'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _resetSettings,
                              icon: Icon(Icons.restore),
                              label: Text('Сбросить'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.orange),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _exportSettings,
                              icon: Icon(Icons.file_download),
                              label: Text('Экспорт'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.blue),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Информация о приложении
              SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Ceiling CRM v1.0',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Система управления коммерческими предложениями',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Разработано для компаний по натяжным потолкам',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
