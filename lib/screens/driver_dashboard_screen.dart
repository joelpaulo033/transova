import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';

class DriverDashboardScreen extends StatefulWidget {
  final AuthService authService;
  const DriverDashboardScreen({super.key, required this.authService});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  late DatabaseReference _driverRef;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    final String driverId = widget.authService.currentUser?.id ?? 'driver_123';
    _driverRef = FirebaseDatabase.instance.ref('drivers/$driverId/current_trip');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-screen Map Background
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(-6.816083, 39.280334), zoom: 14),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),

          // 2. Stream-based UI Overlay
          StreamBuilder<DatabaseEvent>(
            stream: _driverRef.onValue,
            builder: (context, snapshot) {
              final tripData = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;

              if (tripData == null) {
                return _buildIdleState();
              }
              return _buildActiveTripOverlay(tripData);
            },
          ),
        ],
      ),
    );
  }

  // UI when waiting for a trip (The "Go Online" state)
  Widget _buildIdleState() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("You are offline", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text("Go Online"),
                value: true,
                onChanged: (val) {},
                activeColor: TransovaTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Overlay for active trip
  Widget _buildActiveTripOverlay(Map<dynamic, dynamic> trip) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.6,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              const Center(child: Icon(Icons.drag_handle)),
              Text('Trip to ${trip['dropoff_location']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(leading: const Icon(Icons.person), title: Text("Passenger: ${trip['passenger_name'] ?? 'John Doe'}")),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: TransovaTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("ARRIVED AT PICKUP", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}