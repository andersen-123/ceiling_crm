import 'dart:convert';
import 'package:flutter/services.dart';

class PositionLoaderService {
  // Загружает все позиции из JSON файла
  static Future<List<Map<String, dynamic>>> loadAllPositions() async {
    try {
      // Читаем файл из assets
      final String jsonString = await rootBundle.loadString('assets/standard_positions.json');
      
      // Парсим JSON
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      // Преобразуем в List<Map>
      final List<Map<String, dynamic>> positions = [];
      
      for (final item in jsonList) {
        if (item is Map<String, dynamic>) {
          positions.add(item);
        }
      }
      
      print('✅ Загружено ${positions.length} позиций');
      return positions;
    } catch (error) {
      print('❌ Ошибка загрузки позиций: $error');
      
      // Возвращаем пустой список в случае ошибки
      return [];
    }
  }
}
