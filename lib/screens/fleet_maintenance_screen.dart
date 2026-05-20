import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import 'request_transport_screen.dart';
import 'admin_analytics_screen.dart';
import 'register_vehicle_screen.dart';
import 'service_record_detail_screen.dart';

class FleetMaintenanceScreen extends StatefulWidget {
  final AuthService? authService;
  const FleetMaintenanceScreen({super.key, this.authService});

  @override
  State<FleetMaintenanceScreen> createState() => _FleetMaintenanceScreenState();
}

class _FleetMaintenanceScreenState extends State<FleetMaintenanceScreen> {
  int _currentMobileNavIndex = 2;

  // Helper for TZS conversion: $1 USD = 2600 TZS
  String formatCurrency(double usdAmount) {
    double tzsAmount = usdAmount * 2600;
    return 'TZS ${tzsAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}';
  }

  void _onNavTap(int index) {
    if (index == _currentMobileNavIndex) return;

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

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final user = widget.authService?.currentUser;
    final isAuthorized = user != null && user.role != UserRole.guest;
    final canManageFleet = user?.role == UserRole.admin || user?.role == UserRole.manager;

    // SECURITY GUARD: Guests cannot access Fleet Maintenance
    if (!isAuthorized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: TransovaTheme.error),
              const SizedBox(height: 16),
              const Text('Access Denied: Staff/Admin Only', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Return to Dashboard')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TransovaTheme.background,
      appBar: _buildAdaptiveHeader(isDesktop),
      drawer: isDesktop ? null : _buildDrawer(context),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNavigationBar(),
      // GATED UI: Only Admins/Managers can add vehicles
      floatingActionButton: canManageFleet ? _buildExpandableFAB(context, isDesktop) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDashboardHeader(isDesktop),
                  const SizedBox(height: 24),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 8, child: _buildCalendarCard()),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: _buildSidePanelActions()),
                      ],
                    )
                  else ...[
                    _buildCalendarCard(),
                    const SizedBox(height: 24),
                    _buildSidePanelActions(),
                  ],
                  const SizedBox(height: 24),
                  _buildPendingRequestsTable(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAdaptiveHeader(bool isDesktop) {
    return AppBar(
      backgroundColor: TransovaTheme.surface,
      elevation: 0,
      title: const Text('Fleet Maintenance', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
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
          ListTile(leading: const Icon(Icons.dashboard), title: const Text('Home'), onTap: () => _onNavTap(0)),
          ListTile(leading: const Icon(Icons.local_shipping), title: const Text('Bookings'), onTap: () => _onNavTap(1)),
          ListTile(leading: const Icon(Icons.inventory, color: TransovaTheme.primary), title: const Text('Fleet', style: TextStyle(color: TransovaTheme.primary, fontWeight: FontWeight.bold)), onTap: () => Navigator.pop(context)),
          if (user?.role == UserRole.admin)
            ListTile(leading: const Icon(Icons.analytics), title: const Text('Admin Panel'), onTap: () => _onNavTap(3)),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () => widget.authService?.logout()),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manage Fleet Health', style: Theme.of(context).textTheme.headlineMedium),
        const Text('Schedule and track vehicle service intervals.', style: TextStyle(color: TransovaTheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TransovaTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: TransovaTheme.outlineVariant)),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Maintenance Calendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('November 2024', style: TextStyle(color: TransovaTheme.primary)),
            ],
          ),
          SizedBox(height: 200, child: Center(child: Text('Calendar View Placeholder'))),
        ],
      ),
    );
  }

  Widget _buildSidePanelActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TransovaTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: TransovaTheme.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Action Required', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.error)),
          const SizedBox(height: 16),
          _buildActionItem('TRK-8829', 'Brake Inspection', 'Due in 14h'),
          _buildActionItem('TRK-4421', 'Oil Change', 'Due in 3d'),
        ],
      ),
    );
  }

  Widget _buildActionItem(String id, String task, String due) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$id: $task', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(due, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceRecordDetailScreen(authService: widget.authService!))),
    );
  }

  Widget _buildPendingRequestsTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: TransovaTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: TransovaTheme.outlineVariant)),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('VEHICLE')),
          DataColumn(label: Text('SERVICE')),
          DataColumn(label: Text('EST. COST')),
          DataColumn(label: Text('STATUS')),
        ],
        rows: [
          DataRow(cells: [
            const DataCell(Text('TRK-8829')),
            const DataCell(Text('Full Service')),
            DataCell(Text(formatCurrency(850.00))),
            const DataCell(Text('URGENT', style: TextStyle(color: TransovaTheme.error, fontWeight: FontWeight.bold))),
          ]),
          DataRow(cells: [
            const DataCell(Text('VAN-0012')),
            const DataCell(Text('Tire Rotation')),
            DataCell(Text(formatCurrency(120.00))),
            const DataCell(Text('SCHEDULED', style: TextStyle(color: TransovaTheme.secondary))),
          ]),
        ],
      ),
    );
  }

  Widget _buildExpandableFAB(BuildContext context, bool isDesktop) {
    return FloatingActionButton.extended(
      backgroundColor: TransovaTheme.primary,
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterVehicleScreen())),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Add Vehicle', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildMobileBottomNavigationBar() {
    final user = widget.authService?.currentUser;
    return NavigationBar(
      selectedIndex: _currentMobileNavIndex,
      onDestinationSelected: _onNavTap,
      destinations: [
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Bookings'),
        const NavigationDestination(icon: Icon(Icons.inventory), label: 'Fleet'),
        NavigationDestination(icon: Icon(user?.role == UserRole.admin ? Icons.analytics : Icons.person_outline), label: user?.role == UserRole.admin ? 'Admin' : 'Account'),
      ],
    );
  }
}