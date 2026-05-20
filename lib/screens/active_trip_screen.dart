import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import 'request_transport_screen.dart';
import 'fleet_maintenance_screen.dart';
import 'admin_analytics_screen.dart';

class ActiveTripScreen extends StatefulWidget {
  final AuthService? authService;
  const ActiveTripScreen({super.key, this.authService});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  int _speed = 64;
  late Timer _telemetryTimer;
  final Random _random = Random();
  bool _isTripEnded = false;
  final int _currentNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          final variance = _random.nextInt(5) - 2;
          _speed = (_speed + variance).clamp(58, 68);
        });
      }
    });
  }

  @override
  void dispose() {
    _telemetryTimer.cancel();
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
        return;
      case 2:
        nextScreen = FleetMaintenanceScreen(authService: widget.authService);
        break;
      case 3:
        if (user?.role == UserRole.admin) {
          nextScreen = AdminAnalyticsScreen(authService: widget.authService!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access Denied')));
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
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    // PERMISSION CHECK: Only Driver, Manager, or Admin can access Active Trip
    final isAuthorized = user?.role == UserRole.driver ||
        user?.role == UserRole.manager ||
        user?.role == UserRole.admin;

    if (!isAuthorized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: TransovaTheme.error),
              const Text('Access Denied: Drivers & Operations only', style: TextStyle(fontSize: 18)),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TransovaTheme.surface,
      appBar: _buildTopAppBar(isDesktop),
      drawer: isDesktop ? null : _buildDrawer(context),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(
                    Icons.map,
                    size: 80,
                    color: TransovaTheme.outlineVariant,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: _buildTelemetryOverlayColumn(),
            ),
            if (isDesktop)
              Positioned(
                top: 16,
                right: 16,
                bottom: 16,
                child: SizedBox(
                  width: 360,
                  child: _buildTripDetailsSideRail(),
                ),
              ),
            if (!isDesktop)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _buildMobileActionBar(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop ? null : NavigationBar(
        selectedIndex: _currentNavIndex,
        backgroundColor: TransovaTheme.surface,
        indicatorColor: TransovaTheme.secondaryContainer,
        onDestinationSelected: _onNavTap,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.event_note), label: 'Bookings'),
          const NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Fleet'),
          NavigationDestination(
              icon: Icon(user?.role == UserRole.admin ? Icons.analytics : Icons.person_outline),
              label: user?.role == UserRole.admin ? 'Admin' : 'Account'
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar(bool isDesktop) {
    return AppBar(
      backgroundColor: TransovaTheme.surface,
      elevation: 0,
      title: const Text('Live Trip', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
      leading: isDesktop
          ? IconButton(icon: const Icon(Icons.arrow_back, color: TransovaTheme.primary), onPressed: () => Navigator.pop(context))
          : Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: TransovaTheme.primary), onPressed: () => Scaffold.of(context).openDrawer())),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined, color: TransovaTheme.primary), onPressed: () {}),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = widget.authService?.currentUser;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: TransovaTheme.primary),
            accountName: Text(user?.displayName ?? 'Guest'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: TransovaTheme.primary)),
          ),
          ListTile(leading: const Icon(Icons.dashboard), title: const Text('Dashboard'), onTap: () => _onNavTap(0)),
          ListTile(leading: const Icon(Icons.event_note, color: TransovaTheme.primary), title: const Text('Active Trip', style: TextStyle(color: TransovaTheme.primary, fontWeight: FontWeight.bold)), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.inventory), title: const Text('Fleet'), onTap: () => _onNavTap(2)),
          if (user?.role == UserRole.admin)
            ListTile(leading: const Icon(Icons.analytics), title: const Text('Admin Panel'), onTap: () => _onNavTap(3)),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () => widget.authService?.logout()),
        ],
      ),
    );
  }

  Widget _buildTelemetryOverlayColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TransovaTheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SPEED', style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$_speed', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: TransovaTheme.primary)),
                  const SizedBox(width: 4),
                  const Text('km/h', style: TextStyle(fontSize: 16, color: TransovaTheme.onSurfaceVariant)),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetailsSideRail() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TRIP DETAILS', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary, fontSize: 16)),
          const SizedBox(height: 24),
          const Text('Destination', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TransovaTheme.outline)),
          const Text('Apex Manufacturing Co.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: TransovaTheme.error, foregroundColor: Colors.white),
              onPressed: _showEndTripConfirmation,
              child: const Text('END TRIP', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next: Industrial Pkwy', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('ETA 14:42', style: TextStyle(fontSize: 12, color: TransovaTheme.outline)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showEndTripConfirmation,
            style: ElevatedButton.styleFrom(backgroundColor: TransovaTheme.error, foregroundColor: Colors.white),
            child: const Text('END TRIP'),
          )
        ],
      ),
    );
  }

  void _showEndTripConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip?'),
        content: const Text('Are you sure you want to end this trip?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isTripEnded = true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}