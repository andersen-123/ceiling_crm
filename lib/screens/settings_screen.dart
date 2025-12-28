import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/company_profile.dart';
import 'package:ceiling_crm/services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  
  late CompanyProfile _companyProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _bankDetailsController = TextEditingController();
  final TextEditingController _directorNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
  }

  Future<void> _loadCompanyProfile() async {
    try {
      _companyProfile = await _dbHelper.getCompanyProfile();
      
      // Инициализируем контроллеры
      _companyNameController.text = _companyProfile.companyName;
      _addressController.text = _companyProfile.address;
      _phoneController.text = _companyProfile.phone;
      _emailController.text = _companyProfile.email;
      _websiteController.text = _companyProfile.website;
      _bankDetailsController.text = _companyProfile.bankDetails;
      _directorNameController.text = _companyProfile.directorName;
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Ошибка загрузки профиля компании: $e');
      _showErrorDialog('Ошибка загрузки', 'Не удалось загрузить настройки компании');
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
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'Сохранить настройки',
            ),
        ],
      ),
      body: _isSaving
          ? _buildSavingOverlay()
          : _buildSettingsForm(),
    );
  }

  Widget _buildSavingOverlay() {
    return Stack(
      children: [
        Opacity(
          opacity: 0.3,
          child: _buildSettingsForm(),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.business,
                      size: 48,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Сохранение настроек',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Пожалуйста, подождите...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная информация
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Основная информация',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Название компании *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название компании';
                        }
                        return null;
                      },
                      onChanged: (value) => _companyProfile.companyName = value,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Адрес',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                      onChanged: (value) => _companyProfile.address = value,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Телефон',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => _companyProfile.phone = value,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => _companyProfile.email = value,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Веб-сайт',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language),
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: (value) => _companyProfile.website = value,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Банковские реквизиты
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Банковские реквизиты',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _bankDetailsController,
                      decoration: const InputDecoration(
                        labelText: 'Банковские реквизиты',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance),
                        helperText: 'Банк, расчетный счет, БИК, корр. счет',
                      ),
                      maxLines: 6,
                      onChanged: (value) => _companyProfile.bankDetails = value,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _directorNameController,
                      decoration: const InputDecoration(
                        labelText: 'ФИО директора',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      onChanged: (value) => _companyProfile.directorName = value,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Кнопки действий
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Действия',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.restore),
                            label: const Text('Сбросить к шаблону'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _resetToTemplate,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Сохранить'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _saveSettings,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    OutlinedButton.icon(
                      icon: const Icon(Icons.preview),
                      label: const Text('Предпросмотр в PDF'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _previewInPdf,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Информация о приложении
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'О приложении',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ListTile(
                      leading: const Icon(Icons.info, color: Colors.blue),
                      title: const Text('Версия приложения'),
                      subtitle: const Text('1.0.0'),
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.code, color: Colors.green),
                      title: const Text('Разработчик'),
                      subtitle: const Text('Ceiling CRM Team'),
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.orange),
                      title: const Text('Поддержка'),
                      subtitle: const Text('support@ceiling-crm.ru'),
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.update, color: Colors.purple),
                      title: const Text('Последнее обновление'),
                      subtitle: Text(DateTime.now().toString().substring(0, 10)),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      try {
        await _dbHelper.updateCompanyProfile(_companyProfile);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Настройки компании сохранены'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        _showErrorDialog('Ошибка сохранения', 'Не удалось сохранить настройки: $e');
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните обязательные поля'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _resetToTemplate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить настройки?'),
        content: const Text('Все текущие настройки будут заменены шаблонными значениями.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final defaultProfile = CompanyProfile();
              
              setState(() {
                _companyProfile = defaultProfile;
                
                _companyNameController.text = defaultProfile.companyName;
                _addressController.text = defaultProfile.address;
                _phoneController.text = defaultProfile.phone;
                _emailController.text = defaultProfile.email;
                _websiteController.text = defaultProfile.website;
                _bankDetailsController.text = defaultProfile.bankDetails;
                _directorNameController.text = defaultProfile.directorName;
              });
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Настройки сброшены к шаблону'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  void _previewInPdf() async {
    try {
      // Создаем тестовое КП с текущими настройками
      final testQuote = Quote(
        clientName: 'Тестовый клиент',
        clientPhone: '+7 (999) 999-99-99',
        clientAddress: 'Тестовый адрес',
        notes: 'Это тестовое коммерческое предложение для проверки настроек компании.',
        totalAmount: 15000.0,
        createdAt: DateTime.now(),
        items: [
          LineItem(
            quoteId: 0,
            name: 'Тестовая позиция 1',
            description: 'Пример описания позиции',
            unitPrice: 5000.0,
            quantity: 2,
            unit: 'шт.',
          ),
          LineItem(
            quoteId: 0,
            name: 'Тестовая позиция 2',
            description: 'Еще один пример',
            unitPrice: 2500.0,
            quantity: 2,
            unit: 'шт.',
          ),
        ],
      );
      
      final pdfService = PdfService();
      await pdfService.previewPdf(testQuote);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF сгенерирован с текущими настройками компании'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog('Ошибка генерации PDF', 'Не удалось создать PDF: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _bankDetailsController.dispose();
    _directorNameController.dispose();
    super.dispose();
  }
}
