// lib/models/service_vehicle.dart

enum LuxuryTier { standard, premium, vip }

class ServiceVehicle {
  final String id;
  final String name;
  final String imageUrl;
  final double basePrice;
  final LuxuryTier tier;
  final int capacity;

  ServiceVehicle({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.basePrice,
    required this.tier,
    required this.capacity,
  });
}