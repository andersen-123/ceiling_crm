import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Настройки по умолчанию
  String _companyName = 'Моя Компания';
  String _companyPhone = '+7 (999) 123-45-67';
  String _companyEmail = 'info@company.ru';
  String _companyAddress = 'г. Москва, ул. Примерная, д. 1';
  double _vatRate = 20.0; // НДС
  double _defaultMargin = 30.0; // Наценка по умолчанию
  
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _vatController = TextEditingController();
  TextEditingController _marginController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _companyName = prefs.getString('company_name') ?? 'Моя Компания';
      _companyPhone = prefs.getString('company_phone') ?? '+7 (999) 123-45-67';
      _companyEmail = prefs.getString('company_email') ?? 'info@company.ru';
      _companyAddress = prefs.getString('company_address') ?? 'г. Москва, ул. Примерная, д. 1';
      _vatRate = prefs.getDouble('vat_rate') ?? 20.0;
      _defaultMargin = prefs.getDouble('default_margin') ?? 30.0;
      
      _nameController.text = _companyName;
      _phoneController.text = _companyPhone;
      _emailController.text = _companyEmail;
      _addressController.text = _companyAddress;
      _vatController.text = _vatRate.toString();
      _marginController.text = _defaultMargin.toString();
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('company_name', _nameController.text);
      await prefs.setString('company_phone', _phoneController.text);
      await prefs.setString('company_email', _emailController.text);
      await prefs.setString('company_address', _addressController.text);
      await prefs.setDouble('vat_rate', double.parse(_vatController.text));
      await prefs.setDouble('default_margin', double.parse(_marginController.text));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Настройки сохранены'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _loadSettings();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Настройки сброшены к значениям по умолчанию'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки компании'),
        backgroundColor: Colors.blueGrey[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок раздела
              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Данные компании для КП',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
              
              // Название компании
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название компании',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название компании';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Телефон
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Телефон',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              
              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              
              // Адрес
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Адрес',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 2,
              ),
              SizedBox(height: 24),
              
              // Настройки расчетов
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Настройки расчетов',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
              
              // НДС
              TextFormField(
                controller: _vatController,
                decoration: InputDecoration(
                  labelText: 'Ставка НДС (%)',
                  prefixIcon: Icon(Icons.percent),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixText: '%',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите ставку НДС';
                  }
                  final val = double.tryParse(value);
                  if (val == null || val < 0 || val > 100) {
                    return 'Введите корректное значение (0-100)';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Наценка по умолчанию
              TextFormField(
                controller: _marginController,
                decoration: InputDecoration(
                  labelText: 'Наценка по умолчанию (%)',
                  prefixIcon: Icon(Icons.trending_up),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixText: '%',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите наценку';
                  }
                  final val = double.tryParse(value);
                  if (val == null || val < 0) {
                    return 'Введите корректное значение';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              
              // Кнопки сохранения
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: Icon(Icons.save),
                      label: Text('Сохранить настройки'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetSettings,
                      icon: Icon(Icons.restore),
                      label: Text('Сбросить'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Информация о версии
              Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Ceiling CRM v1.0',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Разработано для управления КП',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
