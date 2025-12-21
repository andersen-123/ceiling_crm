class Estimate {
  int? id;
  String name;
  double total;

  Estimate({this.id, required this.name, required this.total});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'total': total};
  }

  factory Estimate.fromMap(Map<String, dynamic> map) {
    return Estimate(
      id: map['id'],
      name: map['name'],
      total: map['total'],
    );
  }
}
