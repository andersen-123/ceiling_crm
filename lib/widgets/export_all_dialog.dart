import 'package:flutter/material.dart';
import '../services/excel_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ExportAllDialog extends StatefulWidget {
  const ExportAllDialog({super.key});

  @override
  ExportAllDialogState createState() => ExportAllDialogState();
}

class ExportAllDialogState extends State<ExportAllDialog> {
  final ExcelService _excelService = ExcelService();
  bool _isExporting = false;
  double _progress = 0.0;
  String _status = 'Подготовка...';
  int _totalQuotes = 0;
  int _processedQuotes = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Экспорт всех КП в Excel'),
      content: SizedBox(
        height: 150,
        child: Column(
          children: [
            if (_isExporting) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
              Text(_status),
              const SizedBox(height: 8),
              Text('Обработано: $_processedQuotes из $_totalQuotes'),
            ] else ...[
              const Icon(Icons.table_chart, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Создать единый Excel файл со всеми коммерческими предложениями?',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isExporting) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _exportAllQuotes,
            child: const Text('Экспортировать'),
          ),
        ],
      ],
    );
  }

  Future<void> _exportAllQuotes() async {
    setState(() {
      _isExporting = true;
      _status = 'Начало экспорта...';
    });

    try {
      // Показываем прогресс
      setState(() {
        _status = 'Получение данных из базы...';
        _progress = 0.1;
      });

      // Генерируем Excel файл со всеми КП
      final excelFile = await _excelService.exportAllQuotesToExcel();

      setState(() {
        _status = 'Файл создан!';
        _progress = 1.0;
      });

      // Закрываем диалог и показываем результат
      Navigator.pop(context);
      
      // Показываем диалог с результатом
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Экспорт завершен'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Все КП успешно экспортированы в Excel файл.'),
              const SizedBox(height: 8),
              Text(
                'Файл: ${excelFile.path.split('/').last}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Размер: ${(excelFile.lengthSync() / 1024).toStringAsFixed(2)} KB',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
            ElevatedButton(
              onPressed: () => _shareFile(excelFile),
              child: const Text('Поделиться'),
            ),
            ElevatedButton(
              onPressed: () => _saveToDownloads(excelFile),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      );
    } catch (error) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка экспорта'),
          content: Text('Не удалось экспортировать данные: $error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _shareFile(File file) async {
    try {
      final uri = Uri(
        scheme: 'file',
        path: file.path,
      );

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка шаринга: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveToDownloads(File file) async {
    try {
      final directory = await getDownloadsDirectory() ?? await getTemporaryDirectory();
      final fileName = 'Все_КП_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final newFile = File('${directory.path}/$fileName');
      
      await file.copy(newFile.path);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл сохранен: ${newFile.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
