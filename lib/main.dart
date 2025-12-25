// lib/main.dart - ВЕСЬ ПРОЕКТ В ОДНОМ ФАЙЛЕ
import 'package:flutter/material.dart';

void main() => runApp(CeilingCRMApp());

class CeilingCRMApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ceiling CRM',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _estimates = [
    {'client': 'Иванов Иван', 'area': 25.5, 'price': 7650, 'address': 'ул. Ленина, 123'},
    {'client': 'Петров Петр', 'area': 18.0, 'price': 5400, 'address': 'ул. Советская, 45'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ceiling CRM ✅')),
      body: Column(
        children: [
          // Статистика
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    Text('${_estimates.length}', style: TextStyle(fontSize: 24)),
                    Text('Смет'),
                  ]),
                  Column(children: [
                    Text('${_estimates.fold(0, (sum, e) => sum + e['price'])} руб.', style: TextStyle(fontSize: 24)),
                    Text('Общая сумма'),
                  ]),
                ],
              ),
            ),
          ),
          
          // Список смет
          Expanded(
            child: ListView.builder(
              itemCount: _estimates.length,
              itemBuilder: (context, index) {
                final estimate = _estimates[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.assignment, color: Colors.blue),
                    title: Text(estimate['client']),
                    subtitle: Text('${estimate['area']} м² • ${estimate['address']}'),
                    trailing: Text('${estimate['price']} руб.'),
                    onTap: () => _showEstimateDetails(estimate),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      
      // Калькулятор
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCalculator,
        icon: Icon(Icons.calculate),
        label: Text('Рассчитать'),
      ),
    );
  }

  void _showCalculator() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Калькулятор потолка'),
        content: CalculatorDialog(),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          ElevatedButton(onPressed: () => _addEstimate(), child: Text('Сохранить')),
        ],
      ),
    );
  }

  void _addEstimate() {
    setState(() {
      _estimates.add({
        'client': 'Новый клиент ${_estimates.length + 1}',
        'area': 20.0,
        'price': 6000,
        'address': 'Новый адрес',
      });
    });
    Navigator.pop(context);
  }

  void _showEstimateDetails(Map<String, dynamic> estimate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Смета: ${estimate['client']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('Площадь'), trailing: Text('${estimate['area']} м²')),
            ListTile(title: Text('Адрес'), trailing: Text(estimate['address'])),
            ListTile(title: Text('Сумма'), trailing: Text('${estimate['price']} руб.', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Закрыть')),
        ],
      ),
    );
  }
}

class CalculatorDialog extends StatefulWidget {
  @override
  _CalculatorDialogState createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  double _area = 20.0;
  double _pricePerMeter = 300.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Площадь: ${_area.toStringAsFixed(1)} м²'),
        Slider(
          value: _area,
          min: 5,
          max: 100,
          divisions: 95,
          onChanged: (value) => setState(() => _area = value),
        ),
        
        SizedBox(height: 20),
        
        Text('Цена за м²: ${_pricePerMeter.toInt()} руб.'),
        Slider(
          value: _pricePerMeter,
          min: 100,
          max: 1000,
          divisions: 18,
          onChanged: (value) => setState(() => _pricePerMeter = value),
        ),
        
        SizedBox(height: 20),
        
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('ИТОГО:', style: TextStyle(fontSize: 18)),
                Text('${(_area * _pricePerMeter).toStringAsFixed(0)} руб.', 
                     style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
