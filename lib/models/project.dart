
import 'project_worker.dart';

class Project {
  int? id;
  final String title; // "Объект: Нежинская 1к2"
  final int? clientId;
  final double contractSum; // Сумма договора (главный доход)
  final double prepaymentReceived; // Полученный аванс
  final String status; // 'plan', 'active', 'completed', 'paid'
  final DateTime createdAt;
  final DateTime? deadline;
  final List<ProjectWorker> workers; // Бригада на этом объекте

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
      contractSum: map['contract_sum'],
      prepaymentReceived: map['prepayment_received'],
      status: map['status'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'])
          : null,
      workers: [], // Работники загружаются отдельным запросом
    );
  }
}
