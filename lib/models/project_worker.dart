class ProjectWorker {
  int? id;
  final int projectId;
  final String name;
  final bool hasCar;
  double salaryCalculated;

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
      salaryCalculated: map['salary_calculated'] is int
          ? (map['salary_calculated'] as int).toDouble()
          : map['salary_calculated'],
    );
  }

  ProjectWorker copyWith({
    int? id,
    int? projectId,
    String? name,
    bool? hasCar,
    double? salaryCalculated,
  }) {
    return ProjectWorker(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      hasCar: hasCar ?? this.hasCar,
      salaryCalculated: salaryCalculated ?? this.salaryCalculated,
    );
  }
}
