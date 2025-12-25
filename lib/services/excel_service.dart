// Сервис для генерации Excel-файлов коммерческих предложений.
// Формирует .xlsx файлы с отдельными листами для данных, работ и оборудования.

import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';
import '../data/database_helper.dart';

class ExcelService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Основной метод генерации Excel файла
  Future<File> generateQuoteExcel(Quote quote) async {
    // Получаем дополнительные данные
    final company = await _dbHelper.getDefaultCompany();
    final lineItems = await _dbHelper.getLineItemsForQuote(quote.id!);
    final workItems = lineItems.where((item) => item.section == 'work').toList();
    final equipmentItems = lineItems.where((item) => item.section == 'equipment').toList();

    // Создаем Excel документ
    final excel = Excel.createExcel();
    
    // Удаляем дефолтный лист
    excel.rename('Sheet1', 'КП_${quote.id}');

    // Лист 1: Основная информация
    final mainSheet = excel['КП_${quote.id}'];
    _addMainInfoSheet(mainSheet, quote, company);

    // Лист 2: Работы
    if (workItems.isNotEmpty) {
      final workSheet = excel['Работы'] ?? excel['Работы'] = excel['Работы'];
      _addItemsSheet(workSheet, workItems, 'РАБОТЫ', quote.currencyCode);
    }

    // Лист 3: Оборудование
    if (equipmentItems.isNotEmpty) {
      final equipmentSheet = excel['Оборудование'] ?? excel['Оборудование'] = excel['Оборудование'];
      _addItemsSheet(equipmentSheet, equipmentItems, 'ОБОРУДОВАНИЕ', quote.currencyCode);
    }

    // Лист 4: Итоги
    final summarySheet = excel['Итоги'] ?? excel['Итоги'] = excel['Итоги'];
    _addSummarySheet(summarySheet, quote, workItems.length, equipmentItems.length);

    // Сохраняем файл
    final fileName = 'КП_${quote.id}_${quote.customerName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    
    final file = File(filePath)
      ..createSync(recursive: true);
    
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    
    return file;
  }

  // Лист с основной информацией
  void _addMainInfoSheet(Sheet sheet, Quote quote, CompanyProfile? company) {
    // Заголовок
    _setCell(sheet, 0, 0, 'КОММЕРЧЕСКОЕ ПРЕДЛОЖЕНИЕ', bold: true, fontSize: 16);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0));
    
    // Информация о компании
    _setCell(sheet, 0, 2, 'Исполнитель:', bold: true);
    if (company != null) {
      _setCell(sheet, 1, 2, company.name);
      if (company.phone != null) _setCell(sheet, 1, 3, 'Тел: ${company.phone!}');
      if (company.email != null) _setCell(sheet, 1, 4, 'Email: ${company.email!}');
      if (company.address != null) _setCell(sheet, 1, 5, 'Адрес: ${company.address!}');
    }

    // Информация о клиенте
    _setCell(sheet, 0, 8, 'Клиент:', bold: true);
    _setCell(sheet, 1, 8, quote.customerName);
    if (quote.customerPhone != null) _setCell(sheet, 1, 9, 'Тел: ${quote.customerPhone!}');
    if (quote.customerEmail != null) _setCell(sheet, 1, 10, 'Email: ${quote.customerEmail!}');
    
    _setCell(sheet, 0, 11, 'Объект:', bold: true);
    _setCell(sheet, 1, 11, quote.objectName);
    
    if (quote.address != null) {
      _setCell(sheet, 0, 12, 'Адрес:', bold: true);
      _setCell(sheet, 1, 12, quote.address!);
    }

    // Параметры помещения
    _setCell(sheet, 0, 14, 'Параметры помещения:', bold: true);
    int row = 14;
    
    if (quote.areaS != null) {
      _setCell(sheet, 1, row, 'Площадь: ${quote.areaS} м²');
      row++;
    }
    
    if (quote.perimeterP != null) {
      _setCell(sheet, 1, row, 'Периметр: ${quote.perimeterP} м.п.');
      row++;
    }
    
    if (quote.heightH != null) {
      _setCell(sheet, 1, row, 'Высота: ${quote.heightH} м');
      row++;
    }
    
    if (quote.ceilingSystem != null) {
      _setCell(sheet, 1, row, 'Тип системы: ${quote.ceilingSystem}');
      row++;
    }

    // Условия и примечания
    row += 2;
    _setCell(sheet, 0, row, 'Условия оплаты:', bold: true);
    if (quote.paymentTerms != null) {
      _setCell(sheet, 1, row, quote.paymentTerms!);
      row++;
    }

    _setCell(sheet, 0, row, 'Условия монтажа:', bold: true);
    if (quote.installationTerms != null) {
      _setCell(sheet, 1, row, quote.installationTerms!);
      row++;
    }

    _setCell(sheet, 0, row, 'Примечания:', bold: true);
    if (quote.notes != null) {
      _setCell(sheet, 1, row, quote.notes!);
    }

    // Номер и дата КП
    _setCell(sheet, 4, 2, '№ КП: ${quote.id}', bold: true);
    _setCell(sheet, 4, 3, 'Дата: ${_formatDate(quote.createdAt)}');
    _setCell(sheet, 4, 4, 'Статус: ${_getStatusText(quote.status)}');

    // Настраиваем ширину колонок
    sheet.setColWidth(0, 20);
    sheet.setColWidth(1, 40);
    sheet.setColWidth(2, 15);
    sheet.setColWidth(3, 15);
    sheet.setColWidth(4, 20);
  }

  // Лист с позициями (работы или оборудование)
  void _addItemsSheet(Sheet sheet, List<LineItem> items, String title, String currencyCode) {
    // Заголовок
    _setCell(sheet, 0, 0, title, bold: true, fontSize: 14);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0));

    // Заголовки таблицы
    final headers = ['№', 'Описание', 'Ед. изм.', 'Количество', 'Цена', 'Сумма'];
    for (int i = 0; i < headers.length; i++) {
      _setCell(sheet, i, 2, headers[i], bold: true, alignCenter: true, bgColor: 'FFE0E0E0');
    }

    // Данные
    double total = 0.0;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final row = i + 3;
      
      _setCell(sheet, 0, row, (i + 1).toString(), alignCenter: true);
      _setCell(sheet, 1, row, item.description);
      _setCell(sheet, 2, row, item.unit, alignCenter: true);
      _setCell(sheet, 3, row, item.quantity.toStringAsFixed(2), alignRight: true);
      _setCell(sheet, 4, row, _formatCurrency(item.price, currencyCode), alignRight: true);
      _setCell(sheet, 5, row, _formatCurrency(item.amount, currencyCode), alignRight: true);
      
      total += item.amount;
    }

    // Итоговая строка
    final totalRow = items.length + 3;
    _setCell(sheet, 0, totalRow, 'ИТОГО:', bold: true, alignRight: true);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow));
    _setCell(sheet, 5, totalRow, _formatCurrency(total, currencyCode), bold: true, alignRight: true, bgColor: 'FFD0E0FF');

    // Настраиваем ширину колонок
    sheet.setColWidth(0, 8);   // №
    sheet.setColWidth(1, 50);  // Описание
    sheet.setColWidth(2, 12);  // Ед. изм.
    sheet.setColWidth(3, 15);  // Количество
    sheet.setColWidth(4, 15);  // Цена
    sheet.setColWidth(5, 18);  // Сумма
  }

  // Лист с итогами
  void _addSummarySheet(Sheet sheet, Quote quote, int workCount, int equipmentCount) {
    // Заголовок
    _setCell(sheet, 0, 0, 'СВОДНЫЙ РАСЧЕТ', bold: true, fontSize: 16);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0));

    // Информация о КП
    _setCell(sheet, 0, 2, 'Клиент:', bold: true);
    _setCell(sheet, 1, 2, quote.customerName);
    
    _setCell(sheet, 0, 3, 'Объект:', bold: true);
    _setCell(sheet, 1, 3, quote.objectName);
    
    _setCell(sheet, 0, 4, 'Дата:', bold: true);
    _setCell(sheet, 1, 4, _formatDate(quote.createdAt));

    // Сводная таблица
    _setCell(sheet, 0, 6, 'РАЗДЕЛ', bold: true, alignCenter: true, bgColor: 'FFE0E0E0');
    _setCell(sheet, 1, 6, 'КОЛИЧЕСТВО ПОЗИЦИЙ', bold: true, alignCenter: true, bgColor: 'FFE0E0E0');
    _setCell(sheet, 2, 6, 'СУММА', bold: true, alignCenter: true, bgColor: 'FFE0E0E0');

    _setCell(sheet, 0, 7, 'Работы', bold: true);
    _setCell(sheet, 1, 7, workCount.toString(), alignCenter: true);
    _setCell(sheet, 2, 7, _formatCurrency(quote.subtotalWork, quote.currencyCode), alignRight: true);

    _setCell(sheet, 0, 8, 'Оборудование', bold: true);
    _setCell(sheet, 1, 8, equipmentCount.toString(), alignCenter: true);
    _setCell(sheet, 2, 8, _formatCurrency(quote.subtotalEquipment, quote.currencyCode), alignRight: true);

    // Итог
    _setCell(sheet, 0, 10, 'ОБЩИЙ ИТОГ:', bold: true, fontSize: 14);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10),
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10));
    _setCell(sheet, 2, 10, _formatCurrency(quote.totalAmount, quote.currencyCode), 
             bold: true, fontSize: 14, alignRight: true, bgColor: 'FFD0E0FF');

    // Настраиваем ширину колонок
    sheet.setColWidth(0, 25);
    sheet.setColWidth(1, 20);
    sheet.setColWidth(2, 20);
    sheet.setColWidth(3, 15);
  }

  // Вспомогательный метод для установки значения ячейки
  void _setCell(
    Sheet sheet,
    int col,
    int row,
    String value, {
    bool bold = false,
    int fontSize = 11,
    bool alignCenter = false,
    bool alignRight = false,
    String? bgColor,
  }) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    
    // Стили
    final style = CellStyle(
      bold: bold,
      fontSize: fontSize,
      horizontalAlign: alignCenter 
          ? HorizontalAlign.Center 
          : alignRight 
            ? HorizontalAlign.Right 
            : HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    
    if (bgColor != null) {
      style.fill = FillPattern.solid(bgColor);
    }
    
    cell.cellStyle = style;
  }

  // Форматирование валюты
  String _formatCurrency(double amount, String currencyCode) {
    final formatted = amount.toStringAsFixed(2);
    
    switch (currencyCode) {
      case 'RUB':
        return '$formatted ₽';
      case 'USD':
        return '\$$formatted';
      case 'EUR':
        return '€$formatted';
      default:
        return '$formatted $currencyCode';
    }
  }

  // Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Получение текста статуса
  String _getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'Черновик';
      case 'sent':
        return 'Отправлено';
      case 'approved':
        return 'Согласовано';
      case 'completed':
        return 'Выполнено';
      default:
        return status;
    }
  }

  // Метод для экспорта всех КП в один Excel файл
  Future<File> exportAllQuotesToExcel() async {
    final quotes = await _dbHelper.getAllQuotes();
    final excel = Excel.createExcel();
    
    // Удаляем дефолтный лист
    excel.rename('Sheet1', 'Все КП');

    // Лист со списком всех КП
    final summarySheet = excel['Все КП'];
    _addAllQuotesSummarySheet(summarySheet, quotes);

    // Отдельные листы для каждого КП
    for (final quote in quotes) {
      try {
        final lineItems = await _dbHelper.getLineItemsForQuote(quote.id!);
        if (lineItems.isNotEmpty) {
          final sheetName = 'КП ${quote.id} ${quote.customerName}';
          final sheet = excel[sheetName] ?? excel[sheetName] = excel[sheetName];
          _addQuoteDetailsSheet(sheet, quote, lineItems);
        }
      } catch (error) {
        print('Ошибка экспорта КП ${quote.id}: $error');
      }
    }

    // Сохраняем файл
    final fileName = 'Все_КП_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    
    final file = File(filePath)
      ..createSync(recursive: true);
    
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    
    return file;
  }

  // Лист со списком всех КП
  void _addAllQuotesSummarySheet(Sheet sheet, List<Quote> quotes) {
    // Заголовок
    _setCell(sheet, 0, 0, 'СПИСОК ВСЕХ КОММЕРЧЕСКИХ ПРЕДЛОЖЕНИЙ', bold: true, fontSize: 16);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
                CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0));

    // Заголовки таблицы
    final headers = ['№ КП', 'Клиент', 'Объект', 'Дата', 'Статус', 'Работы', 'Оборудование', 'ИТОГО'];
    for (int i = 0; i < headers.length; i++) {
      _setCell(sheet, i, 2, headers[i], bold: true, alignCenter: true, bgColor: 'FFE0E0E0');
    }

    // Данные
    double grandTotal = 0.0;
    for (int i = 0; i < quotes.length; i++) {
      final quote = quotes[i];
      final row = i + 3;
      
      _setCell(sheet, 0, row, quote.id?.toString() ?? '', alignCenter: true);
      _setCell(sheet, 1, row, quote.customerName);
      _setCell(sheet, 2, row, quote.objectName);
      _setCell(sheet, 3, row, _formatDate(quote.createdAt));
      _setCell(sheet, 4, row, _getStatusText(quote.status), alignCenter: true);
      _setCell(sheet, 5, row, _formatCurrency(quote.subtotalWork, quote.currencyCode), alignRight: true);
      _setCell(sheet, 6, row, _formatCurrency(quote.subtotalEquipment, quote.currencyCode), alignRight: true);
      _setCell(sheet, 7, row, _formatCurrency(quote.totalAmount, quote.currencyCode), alignRight: true);
      
      grandTotal += quote.totalAmount;
    }

    // Итоговая строка
    final totalRow = quotes.length + 3;
    _setCell(sheet, 0, totalRow, 'ВСЕГО КП: ${quotes.length}', bold: true, alignRight: true);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
                CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRow));
    _setCell(sheet, 7, totalRow, _formatCurrency(grandTotal, 'RUB'), bold: true, alignRight: true, bgColor: 'FFD0E0FF');

    // Настраиваем ширину колонок
    sheet.setColWidth(0, 10);  // № КП
    sheet.setColWidth(1, 30);  // Клиент
    sheet.setColWidth(2, 20);  // Объект
    sheet.setColWidth(3, 15);  // Дата
    sheet.setColWidth(4, 15);  // Статус
    sheet.setColWidth(5, 15);  // Работы
    sheet.setColWidth(6, 15);  // Оборудование
    sheet.setColWidth(7, 18);  // ИТОГО
  }

  // Лист с деталями КП для общего отчета
  void _addQuoteDetailsSheet(Sheet sheet, Quote quote, List<LineItem> lineItems) {
    _setCell(sheet, 0, 0, 'КП №${quote.id}', bold: true, fontSize: 14);
    _setCell(sheet, 0, 1, 'Клиент: ${quote.customerName}');
    _setCell(sheet, 0, 2, 'Объект: ${quote.objectName}');
    _setCell(sheet, 0, 3, 'Дата: ${_formatDate(quote.createdAt)}');
    _setCell(sheet, 0, 4, 'Статус: ${_getStatusText(quote.status)}');
    _setCell(sheet, 0, 5, 'ИТОГО: ${_formatCurrency(quote.totalAmount, quote.currencyCode)}', bold: true);
  }

  // Метод для получения байтов Excel файла (для шаринга)
  Future<Uint8List> getExcelBytes(Quote quote) async {
    final file = await generateQuoteExcel(quote);
    return await file.readAsBytes();
  }

  // Метод для получения пути к файлу
  Future<String> getExcelFilePath(Quote quote) async {
    final file = await generateQuoteExcel(quote);
    return file.path;
  }
}
