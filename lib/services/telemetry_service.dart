import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transova/models/vehicle_telemetry.dart';

/// Model representing the IoT hardware telemetry from the ESP8266
class DeviceTelemetry {
  final String deviceId;
  final double lat;
  final double lng;
  final double speed;
  final int battery;
  final String status;
  final DateTime lastUpdated;

  DeviceTelemetry({
    required this.deviceId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.battery,
    required this.status,
    required this.lastUpdated,
  });

  factory DeviceTelemetry.fromMap(String id, Map<dynamic, dynamic> data) {
    return DeviceTelemetry(
      deviceId: id,
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      speed: (data['speed'] as num).toDouble(),
      battery: (data['battery'] as int),
      status: data['status'] ?? 'offline',
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        data['lastUpdated'] ?? 0,
      ),
    );
  }
}

final telemetryServiceProvider = Provider((ref) => TelemetryService());

/// Stream provider for specific device telemetry
final deviceTelemetryProvider = StreamProvider.family<DeviceTelemetry?, String>(
  (ref, deviceId) {
    return ref.watch(telemetryServiceProvider).getTelemetryStream(deviceId);
  },
);

class TelemetryService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Listens to real-time IoT data from the hardware module
  Stream<DeviceTelemetry?> getTelemetryStream(String deviceId) {
    return _db.child('telemetry').child(deviceId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return DeviceTelemetry.fromMap(deviceId, data);
    });
  }

  /// Listens to all operational devices (for Manager/Admin maps)
  Stream<List<DeviceTelemetry>> getAllTelemetryStream() {
    return _db.child('telemetry').onValue.map((event) {
      final Map<dynamic, dynamic>? data =
          event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      return data.entries.map((e) {
        return DeviceTelemetry.fromMap(
          e.key.toString(),
          e.value as Map<dynamic, dynamic>,
        );
      }).toList();
    });
  }

  Stream<List<VehicleTelemetry>>? getVehicleStream() {
    return null;
  }
}
