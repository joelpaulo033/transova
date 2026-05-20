import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/telemetry_service.dart';
import '../models/vehicle_telemetry.dart';
import 'dashboard_screen.dart';
import 'request_transport_screen.dart';
import 'admin_analytics_screen.dart';
import 'fleet_maintenance_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  final AuthService? authService;
  const LiveTrackingScreen({super.key, this.authService});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> with SingleTickerProviderStateMixin {
  final int _currentNavIndex = 2;
  late AnimationController _pulseController;
  final TelemetryService _telemetryService = TelemetryService();

  VehicleTelemetry? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    final user = widget.authService?.currentUser;
    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = DashboardScreen(authService: widget.authService!);
        break;
      case 1:
        nextScreen = RequestTransportScreen(authService: widget.authService);
        break;
      case 2:
        return; // Already here
      case 3:
        if (user?.role == UserRole.admin) {
          nextScreen = AdminAnalyticsScreen(authService: widget.authService!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin access required')));
          return;
        }
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService?.currentUser;
    final isAuthorized = user != null && user.role != UserRole.guest;

    // SECURITY GUARD: Guest users cannot access live tracking telemetry
    if (!isAuthorized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: TransovaTheme.error),
              const SizedBox(height: 16),
              const Text('Access Denied: Operational access required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Return to Safety')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TransovaTheme.background,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<VehicleTelemetry>>(
            stream: _telemetryService.getVehicleStream(),
            builder: (context, snapshot) {
              final vehicles = snapshot.data ?? [];
              if (_selectedVehicle == null && vehicles.isNotEmpty) {
                _selectedVehicle = vehicles.first;
              } else if (_selectedVehicle != null && vehicles.isNotEmpty) {
                // Update selected vehicle data if it's in the list
                _selectedVehicle = vehicles.firstWhere(
                        (v) => v.id == _selectedVehicle!.id,
                    orElse: () => vehicles.first
                );
              }

              return Stack(
                children: [
                  Positioned.fill(
                    child: _buildMapCanvasBackground(vehicles),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildTopAppBar(),
                  ),
                  Positioned(
                    top: 80,
                    left: 16,
                    right: 16,
                    child: _buildFloatingSearchAndControls(),
                  ),
                  if (_selectedVehicle != null)
                    Positioned.fill(
                      child: _buildDraggableBottomSheetShell(_selectedVehicle!),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomNavigationBar(),
                  ),
                ],
              );
            }
        ),
      ),
    );
  }

  Widget _buildMapCanvasBackground(List<VehicleTelemetry> vehicles) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPatternPainter(),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: RoutePathPainter(),
            ),
          ),
          ...vehicles.map((v) {
            // Mapping lat/lng to simple screen coordinates for this mock implementation
            double top = 300 + (v.latitude + 6.79) * 5000;
            double left = 200 + (v.longitude - 39.20) * 5000;

            bool isSelected = _selectedVehicle?.id == v.id;

            return Positioned(
              top: top,
              left: left,
              child: GestureDetector(
                onTap: () => setState(() => _selectedVehicle = v),
                child: Column(
                  children: [
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: TransovaTheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          v.id,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isSelected)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 40 * (1.0 + _pulseController.value * 0.8),
                                height: 40 * (1.0 + _pulseController.value * 0.8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: TransovaTheme.primaryContainer.withOpacity(1.0 - _pulseController.value),
                                ),
                              );
                            },
                          ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: v.status == 'Delayed' ? TransovaTheme.error : TransovaTheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                              v.status == 'Delayed' ? Icons.warning : Icons.local_shipping,
                              color: Colors.white,
                              size: 18
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: TransovaTheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: TransovaTheme.outlineVariant, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: TransovaTheme.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 16),
              const Text(
                'Live Tracking',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TransovaTheme.primary),
              ),
            ],
          ),
          const Icon(Icons.notifications_outlined, color: TransovaTheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildFloatingSearchAndControls() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: TransovaTheme.outline),
                const SizedBox(width: 12),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search vehicle or driver...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableBottomSheetShell(VehicleTelemetry vehicle) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.id, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
                      Text('Driver: ${vehicle.driverName}', style: const TextStyle(color: TransovaTheme.onSurfaceVariant)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: vehicle.status == 'In Transit' ? TransovaTheme.secondaryContainer : TransovaTheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      vehicle.status.toUpperCase(),
                      style: TextStyle(
                        color: vehicle.status == 'In Transit' ? TransovaTheme.onSecondaryContainer : TransovaTheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridviewTelemetryMatrix(
                speed: '${vehicle.speed.toStringAsFixed(0)} km/h',
                fuel: '${vehicle.fuelLevel.toStringAsFixed(1)}%',
                temp: '${vehicle.temperature.toStringAsFixed(0)}°C',
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat),
                label: const Text('Contact Driver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TransovaTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    final user = widget.authService?.currentUser;
    return NavigationBar(
      selectedIndex: _currentNavIndex,
      backgroundColor: TransovaTheme.surface,
      indicatorColor: TransovaTheme.secondaryContainer,
      onDestinationSelected: _onNavTap,
      destinations: [
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Bookings'),
        const NavigationDestination(icon: Icon(Icons.explore), label: 'Tracking'),
        NavigationDestination(icon: Icon(user?.role == UserRole.admin ? Icons.analytics : Icons.person_outline), label: user?.role == UserRole.admin ? 'Admin' : 'Account'),
      ],
    );
  }
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    const double spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RoutePathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(50, 200)
      ..lineTo(150, 300)
      ..lineTo(300, 450)
      ..lineTo(250, 600);
    final paint = Paint()
      ..color = TransovaTheme.primary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridviewTelemetryMatrix extends StatelessWidget {
  final String speed;
  final String fuel;
  final String temp;
  const GridviewTelemetryMatrix({super.key, required this.speed, required this.fuel, required this.temp});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildMetric(Icons.speed, 'Speed', speed),
        _buildMetric(Icons.oil_barrel, 'Fuel', fuel),
        _buildMetric(Icons.thermostat, 'Temp', temp),
        _buildMetric(Icons.schedule, 'ETA', '15 min'),
      ],
    );
  }

  Widget _buildMetric(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: TransovaTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: TransovaTheme.primary, size: 20),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: TransovaTheme.outline)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}