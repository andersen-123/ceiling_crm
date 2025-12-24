import 'package:flutter/foundation.dart';
import '../models/estimate.dart';
import '../models/estimate_item.dart';
import '../database/database_helper.dart';

class EstimateProvider with ChangeNotifier {
  List<Estimate> _estimates = [];
  bool _isLoading = false;
  String? _error;

  List<Estimate> get estimates => _estimates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final DatabaseHelper _dbHelper = DatabaseHelper()

  EstimateProvider() {
    _loadEstimates();
  }

  // Загрузка всех смет
  Future<void> _loadEstimates() async {
    _isLoading = true;
    notifyListeners();

    try {
      _estimates = await _dbHelper.getAllEstimates();
      _error = null;
    } catch (e) {
      _error = 'Ошибка загрузки смет: $e';
      if (kDebugMode) {
        print('EstimateProvider load error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Создание новой сметы
  Future<Estimate> createEstimate({
    required String clientName,
    required String address,
    required double area,
    required double perimeter,
    double pricePerMeter = 0.0,
    String? name,
    String? notes,
  }) async {
    final estimate = Estimate(
      clientName: clientName,
      address: address,
      area: area,
      perimeter: perimeter,
      pricePerMeter: pricePerMeter,
      totalPrice: area * pricePerMeter,
      createdDate: DateTime.now(),
      name: name,
      notes: notes,
      items: [],
    );

    final id = await _dbHelper.insertEstimate(estimate);
    final createdEstimate = estimate.copyWith(id: id);
    
    _estimates.insert(0, createdEstimate);
    notifyListeners();
    
    return createdEstimate;
  }

  // Обновление сметы
  Future<void> updateEstimate(Estimate estimate) async {
    try {
      await _dbHelper.updateEstimate(estimate);
      
      final index = _estimates.indexWhere((e) => e.id == estimate.id);
      if (index != -1) {
        _estimates[index] = estimate;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Ошибка обновления сметы: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Удаление сметы
  Future<void> deleteEstimate(int id) async {
    try {
      await _dbHelper.deleteEstimate(id);
      _estimates.removeWhere((estimate) => estimate.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка удаления сметы: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Получение сметы по ID
  Future<Estimate> getEstimate(int id) async {
    try {
      return await _dbHelper.getEstimate(id);
    } catch (e) {
      _error = 'Ошибка получения сметы: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Добавление элемента в смету
  Future<Estimate> addItemToEstimate({
    required int estimateId,
    required EstimateItem item,
  }) async {
    try {
      final estimate = await _dbHelper.getEstimate(estimateId);
      final updatedEstimate = estimate.copyWith(
        items: [...estimate.items, item],
      );
      
      await updateEstimate(updatedEstimate);
      return updatedEstimate;
    } catch (e) {
      _error = 'Ошибка добавления элемента: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Обновление элемента в смете
  Future<Estimate> updateEstimateItem({
    required int estimateId,
    required int itemIndex,
    required EstimateItem updatedItem,
  }) async {
    try {
      final estimate = await _dbHelper.getEstimate(estimateId);
      final newItems = List<EstimateItem>.from(estimate.items);
      
      if (itemIndex >= 0 && itemIndex < newItems.length) {
        newItems[itemIndex] = updatedItem;
      }
      
      final updatedEstimate = estimate.copyWith(items: newItems);
      await updateEstimate(updatedEstimate);
      return updatedEstimate;
    } catch (e) {
      _error = 'Ошибка обновления элемента: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Удаление элемента из сметы
  Future<Estimate> removeItemFromEstimate({
    required int estimateId,
    required int itemIndex,
  }) async {
    try {
      final estimate = await _dbHelper.getEstimate(estimateId);
      final newItems = List<EstimateItem>.from(estimate.items);
      
      if (itemIndex >= 0 && itemIndex < newItems.length) {
        newItems.removeAt(itemIndex);
      }
      
      final updatedEstimate = estimate.copyWith(items: newItems);
      await updateEstimate(updatedEstimate);
      return updatedEstimate;
    } catch (e) {
      _error = 'Ошибка удаления элемента: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Поиск смет
  List<Estimate> searchEstimates(String query) {
    if (query.isEmpty) return _estimates;
    
    final searchQuery = query.toLowerCase();
    return _estimates.where((estimate) {
      return estimate.clientName.toLowerCase().contains(searchQuery) ||
             estimate.address.toLowerCase().contains(searchQuery) ||
             (estimate.name?.toLowerCase() ?? '').contains(searchQuery) ||
             (estimate.notes?.toLowerCase() ?? '').contains(searchQuery);
    }).toList();
  }

  // Обновление данных (например, после изменения в БД)
  Future<void> refresh() async {
    await _loadEstimates();
  }

  // Очистка ошибок
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
