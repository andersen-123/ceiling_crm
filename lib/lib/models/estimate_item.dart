class EstimateItem {
  final String name;
  final String unit;
  final double price;
  final double quantity;

  EstimateItem({
    required this.name,
    required this.unit,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;
}
