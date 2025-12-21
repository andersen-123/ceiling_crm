import 'dart:async';
import '../database/database_helper.dart';
import '../models/estimate.dart';

class AutoSaveService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Timer? _timer;

  void startAutoSave(Estimate estimate, {Duration interval = const Duration(seconds: 10)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      if (estimate.id == null) {
        await _dbHelper.insertEstimate(estimate);
      } else {
        await _dbHelper.updateEstimate(estimate);
      }
    });
  }

  void stop() {
    _timer?.cancel();
  }
}
