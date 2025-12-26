import 'project_worker.dart';

class Project {
  int? id;
  final String title;
  final int? clientId;
  final double contractSum;
  final double prepaymentReceived;
  final String status;
  final DateTime createdAt;
  final DateTime? deadline;
  final List<ProjectWorker> workers;

  // Кэшированные финансовые расчёты
  double _cachedGasolineExpense = 0.0;
  double _cachedMaterialsExpense = 0.0;
  double _cachedAmortization = 0.0;
  Map<String, double> _cachedSalaries = {};

  Project({
    this.id,
    required this.title,
    this.clientId,
    required this.contractSum,
    this.prepaymentReceived = 0.0,
    this.status = 'plan',
    required this.createdAt,
    this.deadline,
    required this.workers,
  });

  void updateCalculations({
    required double gasolineExpense,
    required double materialsExpense,
    required double amortization,
    required Map<String, double> salaries,
  }) {
    _cachedGasolineExpense = gasolineExpense;
    _cachedMaterialsExpense = materialsExpense;
    _cachedAmortization = amortization;
    _cachedSalaries = Map<String, double>.from(salaries);
  }

  double get gasolineExpense => _cachedGasolineExpense;
  double get materialsExpense => _cachedMaterialsExpense;
  double get amortization => _cachedAmortization;
  Map<String, double> get workerSalaries => _cachedSalaries;

  double get remainingAfterExpenses =>
      contractSum - _cachedGasolineExpense - _cachedMaterialsExpense;

  double get amountForDistribution =>
      remainingAfterExpenses - _cachedAmortization;

  double get totalExpenses =>
      _cachedGasolineExpense + _cachedMaterialsExpense + _cachedAmortization;

  double get balance => contractSum - totalExpenses;

  bool get hasDriver => workers.any((worker) => worker.hasCar);

  ProjectWorker? get driver =>
      workers.firstWhere((worker) => worker.hasCar, orElse: () => workers.first);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'client_id': clientId,
      'contract_sum': contractSum,
      'prepayment_received': prepaymentReceived,
      'status': status,
      'created_at': createdAt.millisecondsSinceEpoch,
      'deadline': deadline?.millisecondsSinceEpoch,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      title: map['title'],
      clientId: map['client_id'],
      contractSum: map['contract_sum'] is int
          ? (map['contract_sum'] as int).toDouble()
          : map['contract_sum'],
      prepaymentReceived: map['prepayment_received'] is int
          ? (map['prepayment_received'] as int).toDouble()
          : map['prepayment_received'],
      status: map['status'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'])
          : null,
      workers: [],
    );
  }

  Project copyWith({
    int? id,
    String? title,
    int? clientId,
    double? contractSum,
    double? prepaymentReceived,
    String? status,
    DateTime? createdAt,
    DateTime? deadline,
    List<ProjectWorker>? workers,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      clientId: clientId ?? this.clientId,
      contractSum: contractSum ?? this.contractSum,
      prepaymentReceived: prepaymentReceived ?? this.prepaymentReceived,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      workers: workers ?? this.workers,
    );
  }
}
