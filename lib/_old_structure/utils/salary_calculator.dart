
import '../models/project.dart';
import '../models/project_worker.dart';
import '../models/transaction.dart';

class SalaryCalculator {
  /// Рассчитывает зарплату по вашей формуле:
  /// 1. 100% - бензин водителю
  /// 2. - материалы
  /// 3. - 5% амортизация водителю
  /// 4. Остаток делим на всех работников
  static Map<String, dynamic> calculateSalary({
    required double contractSum,
    required List<Transaction> transactions,
    required List<ProjectWorker> workers,
  }) {
    // 1. Собираем расходы по категориям
    final expenses = _calculateExpenses(transactions);
    
    // 2. Находим водителя
    final driver = workers.firstWhere(
      (worker) => worker.hasCar,
      orElse: () => workers.isNotEmpty ? workers.first : ProjectWorker(
        projectId: 0,
        name: 'Нет водителя',
        hasCar: false,
      ),
    );
    
    // 3. Расчёт по формуле
    double remaining = contractSum;
    
    // Бензин (идёт водителю)
    final gasolineExpense = expenses['Бензин'] ?? 0.0;
    remaining -= gasolineExpense;
    
    // Материалы
    final materialsExpense = _calculateMaterialsExpense(expenses);
    remaining -= materialsExpense;
    
    // Амортизация 5% от остатка (идёт водителю)
    final amortization = remaining * 0.05;
    remaining -= amortization;
    
    // Базовая зарплата на каждого
    final salaryPerWorker = workers.isNotEmpty ? remaining / workers.length : 0.0;
    
    // 4. Распределение зарплат
    final workerSalaries = <String, double>{};
    for (final worker in workers) {
      double salary = salaryPerWorker;
      
      if (worker.id == driver.id) {
        // Водитель получает бензин и амортизацию
        salary += gasolineExpense + amortization;
      }
      
      workerSalaries[worker.name] = salary;
    }
    
    // 5. Финансовая сводка
    return {
      'total_contract': contractSum,
      'expenses_by_category': expenses,
      'gasoline_expense': gasolineExpense,
      'materials_expense': materialsExpense,
      'amortization': amortization,
      'remaining_before_split': remaining + amortization, // До деления
      'salary_per_worker_base': salaryPerWorker,
      'worker_salaries': workerSalaries,
      'driver_name': driver.name,
      'summary_text': _createSummaryText(
        contractSum,
        expenses,
        gasolineExpense,
        materialsExpense,
        amortization,
        workers.length,
        workerSalaries,
        driver.name,
      ),
    };
  }
  
  /// Расчёт расходов по категориям
  static Map<String, double> _calculateExpenses(List<Transaction> transactions) {
    final expenses = <String, double>{};
    
    for (final transaction in transactions) {
      if (transaction.isExpense) {
        expenses.update(
          transaction.category,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }
    
    return expenses;
  }
  
  /// Суммирует все материалы
  static double _calculateMaterialsExpense(Map<String, double> expenses) {
    const materialCategories = [
      'Полотна',
      'Полотна москва',
      'Все полотна',
      'Леруа',
      'Диски',
      'Комплект потолок',
      'Комплект карниза',
      'Световое оборудование',
      'Материалы',
    ];
    
    double total = 0.0;
    for (final category in materialCategories) {
      total += expenses[category] ?? 0.0;
    }
    
    return total;
  }
  
  /// Текстовая сводка (для отображения)
  static String _createSummaryText(
    double contractSum,
    Map<String, double> expenses,
    double gasolineExpense,
    double materialsExpense,
    double amortization,
    int workerCount,
    Map<String, double> workerSalaries,
    String driverName,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== РАСЧЁТ ЗАРПЛАТЫ ===');
    buffer.writeln('Сумма договора: ${contractSum.toStringAsFixed(2)} ₽');
    buffer.writeln('Бригада: $workerCount человек');
    buffer.writeln('Водитель: $driverName');
    buffer.writeln();
    
    buffer.writeln('=== ЭТАПЫ РАСЧЁТА ===');
    buffer.writeln('1. Исходная сумма: ${contractSum.toStringAsFixed(2)} ₽');
    
    if (gasolineExpense > 0) {
      buffer.writeln('2. - Бензин: ${gasolineExpense.toStringAsFixed(2)} ₽');
      buffer.writeln('   Остаток: ${(contractSum - gasolineExpense).toStringAsFixed(2)} ₽');
    }
    
    if (materialsExpense > 0) {
      buffer.writeln('3. - Материалы: ${materialsExpense.toStringAsFixed(2)} ₽');
      buffer.writeln('   Остаток: ${(contractSum - gasolineExpense - materialsExpense).toStringAsFixed(2)} ₽');
    }
    
    if (amortization > 0) {
      buffer.writeln('4. - Амортизация 5%: ${amortization.toStringAsFixed(2)} ₽');
      buffer.writeln('   Остаток к распределению: ${(contractSum - gasolineExpense - materialsExpense - amortization).toStringAsFixed(2)} ₽');
    }
    
    buffer.writeln('5. Делим на $workerCount монтажника(ов)');
    buffer.writeln();
    
    buffer.writeln('=== ЗАРПЛАТА ===');
    for (final entry in workerSalaries.entries) {
      final isDriver = entry.key == driverName;
      buffer.write('${entry.key}');
      if (isDriver) buffer.write(' (водитель)');
      buffer.writeln(': ${entry.value.toStringAsFixed(2)} ₽');
    }
    
    final totalSalaries = workerSalaries.values.fold(0.0, (a, b) => a + b);
    buffer.writeln('Итого выплат: ${totalSalaries.toStringAsFixed(2)} ₽');
    
    return buffer.toString();
  }
  
  /// Обновляет зарплату в объекте проекта
  static void updateProjectSalary(Project project, List<Transaction> transactions) {
    final calculation = calculateSalary(
      contractSum: project.contractSum,
      transactions: transactions,
      workers: project.workers,
    );
    
    project.updateCalculations(
      gasolineExpense: calculation['gasoline_expense'] as double,
      materialsExpense: calculation['materials_expense'] as double,
      amortization: calculation['amortization'] as double,
      salaries: calculation['worker_salaries'] as Map<String, double>,
    );
  }
}
