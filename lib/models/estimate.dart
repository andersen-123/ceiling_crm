class Estimate {
  final int? id;
  final String clientName;
  final double area;
  final double price;

  Estimate({
    this.id,
    required this.clientName,
    required this.area,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'area': area,
      'price': price,
    };
  }

  factory Estimate.fromMap(Map<String, dynamic> map) {
    return Estimate(
      id: map['id'],
      clientName: map['clientName'],
      area: map['area'],
      price: map['price'],
    );
  }
}
