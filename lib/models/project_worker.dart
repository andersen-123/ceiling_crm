
class ProjectWorker {
  int? id;
  final int projectId; // ID проекта, к которому привязан
  final String name; // "Лёша", "Я"
  final bool hasCar; // true - у работника есть автомобиль
  double salaryCalculated; // Рассчитанная зарплата (будет обновляться)

  ProjectWorker({
    this.id,
    required this.projectId,
    required this.name,
    required this.hasCar,
    this.salaryCalculated = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'name': name,
      'has_car': hasCar ? 1 : 0,
      'salary_calculated': salaryCalculated,
    };
  }

  factory ProjectWorker.fromMap(Map<String, dynamic> map) {
    return ProjectWorker(
      id: map['id'],
      projectId: map['project_id'],
      name: map['name'],
      hasCar: map['has_car'] == 1,
      salaryCalculated: map['salary_calculated'],
    );
  }
}
