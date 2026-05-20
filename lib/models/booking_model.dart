class BookingModel {
  final double baseFreight;
  final double fuelSurcharge;
  final double serviceFee;
  final String status;

  BookingModel({
    required this.baseFreight,
    required this.fuelSurcharge,
    required this.serviceFee,
    required this.status,
  });

  factory BookingModel.fromMap(Map<dynamic, dynamic> map) {
    return BookingModel(
      baseFreight: (map['baseFreight'] ?? 1245.00).toDouble(),
      fuelSurcharge: (map['fuelSurcharge'] ?? 186.75).toDouble(),
      serviceFee: (map['serviceFee'] ?? 45.00).toDouble(),
      status: map['status'] ?? 'pending',
    );
  }
}