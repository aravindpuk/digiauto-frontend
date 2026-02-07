class SpareItem {
  String partName;
  String partNumber;
  int quantity;
  double purchaseRate;
  double sellingRate;

  SpareItem({
    required this.partName,
    required this.partNumber,
    required this.quantity,
    required this.purchaseRate,
    required this.sellingRate,
  });

  double get total => quantity * sellingRate;
}
