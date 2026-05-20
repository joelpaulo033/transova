class VehicleTelemetry {
  final String id;
  final double latitude;
  final double longitude;
  final double speed;
  final double fuelLevel;
  final double temperature;
  final String status;
  final String driverName;

  VehicleTelemetry({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.fuelLevel,
    required this.temperature,
    required this.status,
    required this.driverName,
  });

  factory VehicleTelemetry.fromMap(String id, Map<dynamic, dynamic> map) {
    return VehicleTelemetry(
      id: id,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      speed: (map['speed'] ?? 0.0).toDouble(),
      fuelLevel: (map['fuelLevel'] ?? 0.0).toDouble(),
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Unknown',
      driverName: map['driverName'] ?? 'Unknown',
    );
  }
}