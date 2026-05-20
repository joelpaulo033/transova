import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import 'request_transport_screen.dart';
import 'fleet_maintenance_screen.dart';
import 'admin_analytics_screen.dart';

class ServiceRecordDetailScreen extends StatelessWidget {
  final AuthService authService;
  const ServiceRecordDetailScreen({super.key, required this.authService});

  // Requirement 5: Currency Localization ($1 = 2600 TZS)
  String formatCurrency(double usdAmount) {
    double tzsAmount = usdAmount * 2600;
    return 'TZS ${tzsAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = TransovaTheme.lightTheme;
    final textTheme = theme.textTheme;
    final user = authService.currentUser;
    final isAuthorized = user != null && user.role != UserRole.guest;

    // SECURITY GUARD: Guest users cannot access detailed service records
    if (!isAuthorized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: TransovaTheme.error),
              const SizedBox(height: 16),
              const Text('Restricted: Staff Access Only', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Fleet')),
            ],
          ),
        ),
      );
    }

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: TransovaTheme.background,
        appBar: AppBar(
          backgroundColor: TransovaTheme.surface,
          elevation: 0,
          title: Text('Service Details', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: TransovaTheme.primary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: TransovaTheme.onSurfaceVariant),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(TransovaTheme.spaceLg),
          child: Column(
            children: [
              const _VehicleHeroCard(),
              const SizedBox(height: 24),
              _WorkOrderSummaryCard(formatter: formatCurrency),
              const SizedBox(height: 24),
              const _MaintenanceHistoryCard(),
              const SizedBox(height: 24),
              _PartsBreakdownCard(formatter: formatCurrency),
              const SizedBox(height: 24),
              const _TechnicianNotesCard(),
            ],
          ),
        ),
        bottomNavigationBar: MediaQuery.of(context).size.width < 768
            ? _MobileBottomNavigationBar(authService: authService)
            : null,
      ),
    );
  }
}

class _VehicleHeroCard extends StatelessWidget {
  const _VehicleHeroCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TransovaTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, size: 48, color: TransovaTheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TRK-8829', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Text('Freightliner Cascadia 2023', style: TextStyle(color: TransovaTheme.onSurfaceVariant)),
            ],
          )
        ],
      ),
    );
  }
}

class _WorkOrderSummaryCard extends StatelessWidget {
  final String Function(double) formatter;
  const _WorkOrderSummaryCard({required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TransovaTheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildRow('Estimated Parts', formatter(1420.50)),
          _buildRow('Estimated Labor', formatter(850.00)),
          const Divider(color: Colors.white24),
          _buildRow('Total Cost', formatter(2270.50), isTotal: true),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service Approved and Invoiced')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: TransovaTheme.secondary, foregroundColor: Colors.white),
            child: const Center(child: Text('Approve & Invoice')),
          )
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 14)),
        ],
      ),
    );
  }
}

class _MaintenanceHistoryCard extends StatelessWidget {
  const _MaintenanceHistoryCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TransovaTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: TransovaTheme.outlineVariant)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Maintenance History', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
          SizedBox(height: 16),
          Text('• Engine Tuning (Nov 14)'),
          Text('• Tire Rotation (Sep 05)'),
        ],
      ),
    );
  }
}

class _PartsBreakdownCard extends StatelessWidget {
  final String Function(double) formatter;
  const _PartsBreakdownCard({required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TransovaTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: TransovaTheme.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Parts Breakdown', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
          const SizedBox(height: 16),
          _buildPart('Fuel Filter', formatter(450.00)),
          _buildPart('Synthetic Fluid', formatter(280.50)),
          _buildPart('Brake Pad Set', formatter(540.00)),
        ],
      ),
    );
  }

  Widget _buildPart(String name, String cost) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(name), Text(cost, style: const TextStyle(fontWeight: FontWeight.w500))],
      ),
    );
  }
}

class _TechnicianNotesCard extends StatelessWidget {
  const _TechnicianNotesCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TransovaTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: TransovaTheme.outlineVariant)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Technician Notes', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
          SizedBox(height: 8),
          Text('"Noticed slight wear on turbocharger. Detailed inspection recommended at 150k miles."', style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class _MobileBottomNavigationBar extends StatelessWidget {
  final AuthService authService;
  const _MobileBottomNavigationBar({required this.authService});

  @override
  Widget build(BuildContext context) {
    final isAdmin = authService.currentUser?.role == UserRole.admin;
    return NavigationBar(
      onDestinationSelected: (index) {
        Widget? screen;
        if (index == 0) screen = DashboardScreen(authService: authService);
        if (index == 1) screen = RequestTransportScreen(authService: authService);
        if (index == 2) screen = FleetMaintenanceScreen(authService: authService);
        if (index == 3) screen = isAdmin ? AdminAnalyticsScreen(authService: authService) : null;
        if (screen != null) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screen!));
      },
      destinations: [
        const NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Bookings'),
        const NavigationDestination(icon: Icon(Icons.inventory), label: 'Fleet'),
        NavigationDestination(icon: Icon(isAdmin ? Icons.analytics : Icons.person), label: isAdmin ? 'Admin' : 'Account'),
      ],
    );
  }
}