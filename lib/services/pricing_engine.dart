// --- ENUMS ---
enum ServiceCategory { wedding, funeral, convoy, airport, tourism, corporate, cargo, sanitation }
enum VehicleCapacity { seat4, seat6, seat16, seat30, cargoVehicle }

// --- PRICING RESULT MODEL ---
class PricingBreakdown {
  final double distanceKm;
  final double baseRate; // Rate per KM or calculated unit rate
  final double weightKg; // 0 if not applicable
  final double weightUnits; // 0 if not applicable
  final double totalPrice;
  final String formattedTotal;

  PricingBreakdown({
    required this.distanceKm,
    required this.baseRate,
    required this.weightKg,
    required this.weightUnits,
    required this.totalPrice,
    required this.formattedTotal,
  });
}

// --- CORE PRICING ENGINE ---
class PricingEngine {

  // Custom formatter to avoid needing the external 'intl' package
  static String formatCurrency(double amount) {
    return 'TZS ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  static PricingBreakdown calculateFare({
    required double distanceKm,
    required ServiceCategory serviceType,
    required VehicleCapacity vehicleCapacity,
    double weightKg = 0.0,
  }) {
    // 1. Validation to prevent invalid calculations
    if (distanceKm <= 0) throw ArgumentError('Distance must be greater than 0');

    double totalPrice = 0.0;
    double baseRate = 0.0;
    double weightUnits = 0.0;

    // 2. Logic Split: Event Transport vs. Weight Logistics
    bool isWeightBased = serviceType == ServiceCategory.cargo || serviceType == ServiceCategory.sanitation;

    if (isWeightBased) {
      if (weightKg <= 0) throw ArgumentError('Weight is required for Cargo/Sanitation');

      // Weight Calculation: 15,000 TZS per 15 KG per 1 KM
      // Using .ceil() ensures that even 1kg triggers the first 15kg unit block
      weightUnits = (weightKg / 15.0).ceilToDouble();
      baseRate = 15000.0;

      totalPrice = distanceKm * weightUnits * baseRate;

    } else {
      // Event/Passenger Transport Calculation
      baseRate = _getCapacityRate(vehicleCapacity);
      totalPrice = distanceKm * baseRate;
    }

    return PricingBreakdown(
      distanceKm: distanceKm,
      baseRate: baseRate,
      weightKg: weightKg,
      weightUnits: weightUnits,
      totalPrice: totalPrice,
      formattedTotal: formatCurrency(totalPrice),
    );
  }

  static double _getCapacityRate(VehicleCapacity capacity) {
    switch (capacity) {
      case VehicleCapacity.seat4: return 12000.0;
      case VehicleCapacity.seat6: return 20000.0;
      case VehicleCapacity.seat16: return 48000.0;
      case VehicleCapacity.seat30: return 95000.0;
      case VehicleCapacity.cargoVehicle: return 0.0; // Handled by weight logic
    }
  }
}